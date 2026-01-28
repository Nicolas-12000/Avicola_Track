from rest_framework import serializers
from django.utils import timezone

from .models import BreedReference, ReferenceImportLog


class BreedReferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = BreedReference
        fields = ['id', 'breed', 'age_days', 'expected_weight', 'expected_consumption', 'tolerance_range', 'version', 'is_active', 'created_by']
        read_only_fields = ['version', 'created_by']

    def validate(self, data):
        # Basic domain validations mirroring service rules
        age_days = data.get('age_days')
        weight = data.get('expected_weight')
        consumption = data.get('expected_consumption', 0)
        tolerance = data.get('tolerance_range', 10.0)

        if age_days is None or age_days < 0 or age_days > 365:
            raise serializers.ValidationError('Edad inválida')
        if weight is None or weight <= 0:
            raise serializers.ValidationError('Peso inválido')
        if consumption < 0:
            raise serializers.ValidationError('Consumo inválido')
        if tolerance < 0 or tolerance > 100:
            raise serializers.ValidationError('Tolerancia inválida')

        return data


class ReferenceImportLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReferenceImportLog
        fields = ['id', 'file_name', 'imported_by', 'total_rows', 'successful_imports', 'updates', 'errors', 'error_details', 'created_at']
        read_only_fields = fields
from rest_framework import serializers
from django.utils import timezone
from django.core.exceptions import ValidationError
import logging

from apps.flocks.models import Flock
from apps.farms.services import ShedCapacityService
from apps.farms.models import Shed
from django.db import transaction
from drf_spectacular.utils import extend_schema_field, OpenApiTypes

logger = logging.getLogger(__name__)


class FlockSerializer(serializers.ModelSerializer):
    # Use SerializerMethodField and annotate return types so drf-spectacular can infer schema
    current_age_days = serializers.SerializerMethodField()
    survival_rate = serializers.SerializerMethodField()

    class Meta:
        model = Flock
        fields = [
            'id', 'arrival_date', 'initial_quantity', 'current_quantity', 'initial_weight',
            'weight_alert_low', 'weight_alert_high',
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

        # 4. Peso inicial: no bloquear la creación aunque esté fuera del rango.
        # Se aceptan pesos bajos/altos y la detección de anormalidad se maneja
        # creando una alarma después de la creación del lote.

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

            # Generar alarma si el peso inicial está fuera de umbrales configurados
            try:
                from apps.alarms.models import Alarm, AlarmConfiguration

                iw = float(flock.initial_weight) if flock.initial_weight is not None else None
                abnormal = False

                # Preferir umbrales definidos por lote si existen
                if getattr(flock, 'weight_alert_low', None) is not None or getattr(flock, 'weight_alert_high', None) is not None:
                    low = float(flock.weight_alert_low) if flock.weight_alert_low is not None else None
                    high = float(flock.weight_alert_high) if flock.weight_alert_high is not None else None
                    if low is not None and iw is not None and iw < low:
                        abnormal = True
                    if high is not None and iw is not None and iw > high:
                        abnormal = True
                else:
                    # Fallback a rango por defecto (30-60g)
                    if iw is not None and (iw < 30 or iw > 60):
                        abnormal = True

                if abnormal:
                    # Buscar configuración de alarmas de la granja para tipo WEIGHT
                    config = AlarmConfiguration.objects.filter(alarm_type='WEIGHT', farm=flock.shed.farm, is_active=True).first()
                    priority = 'HIGH' if (iw is not None and (iw < 20 or iw > 80)) else 'MEDIUM'

                    Alarm.objects.create(
                        alarm_type='WEIGHT',
                        description=f'Peso inicial anómalo para lote {flock.id}: {iw}g',
                        priority=priority,
                        source_type='flock',
                        source_date=flock.arrival_date,
                        source_id=flock.id,
                        farm=flock.shed.farm,
                        flock=flock,
                        shed=flock.shed,
                        configuration=config
                    )
            except Exception:
                logger.exception('Error creando alarma de peso inicial')

            return flock

    @extend_schema_field(OpenApiTypes.INT)
    def get_current_age_days(self, obj: Flock):
        """Return the current age in days for documentation/schema purposes."""
        try:
            return obj.current_age_days
        except Exception:
            return None

    @extend_schema_field(OpenApiTypes.NUMBER)
    def get_survival_rate(self, obj: Flock):
        """Return survival rate as a percentage (0-100)."""
        try:
            return obj.survival_rate
        except Exception:
            return None
