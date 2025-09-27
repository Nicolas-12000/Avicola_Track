from rest_framework import serializers
from django.utils import timezone
from django.core.exceptions import ValidationError
import logging

from apps.flocks.models import Flock
from apps.farms.services import ShedCapacityService
from apps.farms.models import Shed
from django.db import transaction

logger = logging.getLogger(__name__)


class FlockSerializer(serializers.ModelSerializer):
    current_age_days = serializers.ReadOnlyField()
    survival_rate = serializers.ReadOnlyField()

    class Meta:
        model = Flock
        fields = [
            'id', 'arrival_date', 'initial_quantity', 'current_quantity', 'initial_weight',
            'breed', 'gender', 'supplier', 'shed', 'status', 'current_age_days', 'survival_rate', 'created_by'
        ]
        read_only_fields = ['current_quantity', 'status', 'current_age_days', 'survival_rate', 'created_by']

    def validate(self, data):
        shed = data.get('shed')
        quantity = data.get('initial_quantity')
        user = self.context['request'].user

        # 1. Validar capacidad del galpón
        ShedCapacityService.validate_capacity(shed, quantity)

        # 2. Validar permisos por rol
        user_role_name = getattr(getattr(user, 'role', None), 'name', None)
        if user_role_name == 'Galponero':
            if shed.assigned_worker != user:
                raise ValidationError("No puedes registrar lotes en galpones no asignados")
        elif user_role_name == 'Administrador de Granja':
            if getattr(shed.farm, 'farm_manager', None) != user:
                raise ValidationError("No puedes registrar lotes en granjas que no administras")

        # 3. Validar fecha de llegada
        if data.get('arrival_date') > timezone.now().date():
            raise ValidationError("La fecha de llegada no puede ser futura")

        # 4. Validar peso inicial realista (gramos)
        if data.get('initial_weight') < 30 or data.get('initial_weight') > 60:
            raise ValidationError("Peso inicial fuera del rango normal (30-60 gramos)")

        return data

    def create(self, validated_data):
        """Crear lote de forma transaccional y actualizar estadísticas de granja"""
        # Hacer el proceso transaccional para evitar race conditions en capacidad
        with transaction.atomic():
            shed = Shed.objects.select_for_update().get(pk=validated_data['shed'].pk)

            # Validar capacidad de nuevo dentro del lock
            ShedCapacityService.validate_capacity(shed, validated_data['initial_quantity'])

            # Set created_by from request (auditoría)
            request_user = getattr(self.context.get('request'), 'user', None)
            if request_user and 'created_by' not in validated_data:
                validated_data['created_by'] = request_user

            flock = super().create(validated_data)

            # Actualizar stats de la granja si existe el método
            try:
                if hasattr(flock.shed.farm, 'update_farm_stats'):
                    flock.shed.farm.update_farm_stats()
            except Exception:
                logger.exception('Error al actualizar estadísticas de la granja')

            # Log para trazabilidad
            try:
                logger.info(
                    f"Lote registrado: {flock.initial_quantity} {flock.breed} "
                    f"en {flock.shed.name} por {self.context['request'].user.username}"
                )
            except Exception:
                logger.exception('Error registrando log del lote')

            return flock
