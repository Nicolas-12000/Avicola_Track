import logging
from rest_framework import viewsets, permissions
from .models import Farm
from .serializers import FarmSerializer
from rest_framework import mixins
from rest_framework.routers import DefaultRouter
from apps.farms.models import Shed
from apps.farms.serializers import ShedSerializer
from apps.flocks.permissions import IsAssignedShedWorkerOrFarmAdmin
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiTypes
from .permissions import IsSystemAdminOrReadOnly

logger = logging.getLogger(__name__)


class FarmViewSet(viewsets.ModelViewSet):
    queryset = Farm.objects.all()
    serializer_class = FarmSerializer
    permission_classes = [permissions.IsAuthenticated, IsSystemAdminOrReadOnly]

    @extend_schema(parameters=[OpenApiParameter(name='pk', required=True, type=OpenApiTypes.INT)])
    def retrieve(self, request, *args, **kwargs):
        return super().retrieve(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        role_name = user.role.name if user.role else None

        if role_name == 'Administrador Sistema':
            return Farm.objects.all()
        if role_name == 'Administrador de Granja':
            return user.managed_farms.all()
        if role_name == 'Veterinario':
            return getattr(user, 'assigned_farms', []).all()

        # Galponero: farms where their assigned_sheds belong
        assigned_sheds = getattr(user, 'assigned_sheds', []).all()
        farm_ids = set(s.farm.id for s in assigned_sheds)
        return Farm.objects.filter(id__in=farm_ids)

    def perform_create(self, serializer):
        farm = serializer.save()
        # Placeholder for setting up defaults (alarms etc.)
        logger.info(f"Nueva granja creada: {farm.name} por {self.request.user}")
        return farm
from django.shortcuts import render

# Create your views here.


class ShedViewSet(viewsets.ModelViewSet):
    queryset = Shed.objects.all()
    serializer_class = ShedSerializer
    # Allow farm admins to update sheds within their farms and assigned shed workers
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]

    @extend_schema(parameters=[OpenApiParameter(name='pk', required=True, type=OpenApiTypes.INT)])
    def retrieve(self, request, *args, **kwargs):
        return super().retrieve(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)
        # Start from all sheds and optionally filter by query param
        qs = Shed.objects.all()

        # Allow filtering by farm via query param `farm=<id>`
        farm_param = self.request.query_params.get('farm')
        if farm_param:
            try:
                farm_id = int(farm_param)
                qs = qs.filter(farm_id=farm_id)
            except (TypeError, ValueError):
                return Shed.objects.none()

        # Apply role-based restrictions on top of the (possibly filtered) queryset
        if role_name == 'Administrador Sistema':
            return qs
        if role_name == 'Administrador de Granja':
            return qs.filter(farm__farm_manager=user)
        if role_name == 'Galponero':
            return qs.filter(assigned_worker=user)

        return Shed.objects.none()

