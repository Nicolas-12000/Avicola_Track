import logging
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Farm
from .serializers import FarmSerializer
from rest_framework import mixins
from rest_framework.routers import DefaultRouter
from apps.farms.models import Shed
from apps.farms.serializers import ShedSerializer
from apps.flocks.permissions import IsAssignedShedWorkerOrFarmAdmin
from apps.flocks.mixins import RoleFilteredMixin
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes
from .permissions import IsSystemAdminOrReadOnly

logger = logging.getLogger(__name__)


class FarmViewSet(viewsets.ModelViewSet):
    queryset = Farm.objects.all()
    serializer_class = FarmSerializer
    permission_classes = [permissions.IsAuthenticated, IsSystemAdminOrReadOnly]

    @action(detail=True, methods=['post'], url_path='add-veterinarian')
    def add_veterinarian(self, request, pk=None):
        """Asignar un veterinario a la granja. Solo Admin Sistema o Admin de Granja (dueño)"""
        farm = self.get_object()
        user = request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        # Permisos: System admin puede, Farm admin sólo si es manager de la granja
        if not (user.is_staff or role_name == 'Administrador Sistema' or (role_name == 'Administrador de Granja' and farm.farm_manager == user)):
            return Response({'detail': 'No tienes permisos para asignar veterinarios.'}, status=403)

        vet_id = request.data.get('veterinarian')
        if not vet_id:
            return Response({'detail': 'veterinarian id requerido'}, status=400)

        try:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            vet = User.objects.get(pk=vet_id)
        except Exception:
            return Response({'detail': 'Veterinario no encontrado'}, status=404)

        # Verificar rol del usuario objetivo
        vet_role = getattr(getattr(vet, 'role', None), 'name', None)
        if vet_role != 'Veterinario':
            return Response({'detail': 'El usuario no es un veterinario'}, status=400)

        farm.veterinarians.add(vet)
        farm.save()
        logger.info(f"Veterinario {vet.username} asignado a granja {farm.name} por {user.username}")

        # Crear AuditLog sencillo
        try:
            from apps.users.models import AuditLog
            AuditLog.objects.create(
                actor=user,
                content_type='farms.Farm',
                object_id=str(farm.pk),
                object_repr=str(farm),
                action='updated',
                changes={'veterinarian_added': vet.pk}
            )
        except Exception:
            pass

        return Response({'detail': 'Veterinario asignado correctamente'})

    @action(detail=True, methods=['post'], url_path='remove-veterinarian')
    def remove_veterinarian(self, request, pk=None):
        """Remover un veterinario de la granja."""
        farm = self.get_object()
        user = request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        if not (user.is_staff or role_name == 'Administrador Sistema' or (role_name == 'Administrador de Granja' and farm.farm_manager == user)):
            return Response({'detail': 'No tienes permisos para remover veterinarios.'}, status=403)

        vet_id = request.data.get('veterinarian')
        if not vet_id:
            return Response({'detail': 'veterinarian id requerido'}, status=400)

        try:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            vet = User.objects.get(pk=vet_id)
        except Exception:
            return Response({'detail': 'Veterinario no encontrado'}, status=404)

        farm.veterinarians.remove(vet)
        farm.save()
        logger.info(f"Veterinario {vet.username} removido de granja {farm.name} por {user.username}")

        # Crear AuditLog sencillo
        try:
            from apps.users.models import AuditLog
            AuditLog.objects.create(
                actor=user,
                content_type='farms.Farm',
                object_id=str(farm.pk),
                object_repr=str(farm),
                action='updated',
                changes={'veterinarian_removed': vet.pk}
            )
        except Exception:
            pass

        return Response({'detail': 'Veterinario removido correctamente'})

    @extend_schema(parameters=[OpenApiParameter(name='pk', required=True, type=OpenApiTypes.INT)])
    def retrieve(self, request, *args, **kwargs):
        return super().retrieve(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        role_name = user.role.name if user.role else None

        base_qs = Farm.objects.select_related('farm_manager').prefetch_related('sheds')

        if role_name == 'Administrador Sistema':
            return base_qs.all()
        if role_name == 'Administrador de Granja':
            return base_qs.filter(farm_manager=user)
        if role_name == 'Veterinario':
            return base_qs.filter(veterinarians=user)

        # Galponero: farms where their assigned_sheds belong
        farm_ids = Shed.objects.filter(assigned_worker=user).values_list('farm_id', flat=True)
        return base_qs.filter(id__in=farm_ids)

    def perform_create(self, serializer):
        farm = serializer.save()
        # Placeholder for setting up defaults (alarms etc.)
        logger.info(f"Nueva granja creada: {farm.name} por {self.request.user}")
        return farm
# Create your views here.


class ShedViewSet(RoleFilteredMixin, viewsets.ModelViewSet):
    queryset = Shed.objects.all()
    serializer_class = ShedSerializer
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]
    role_flock_path = None
    role_farm_path = 'farm'
    role_galponero_path = 'assigned_worker'

    @extend_schema(parameters=[OpenApiParameter(name='pk', required=True, type=OpenApiTypes.INT)])
    def retrieve(self, request, *args, **kwargs):
        return super().retrieve(request, *args, **kwargs)

    def get_queryset(self):
        qs = Shed.objects.select_related('farm', 'assigned_worker').all()

        farm_param = self.request.query_params.get('farm')
        if farm_param:
            try:
                farm_id = int(farm_param)
                qs = qs.filter(farm_id=farm_id)
            except (TypeError, ValueError):
                return Shed.objects.none()

        return self.apply_role_filter(qs)

