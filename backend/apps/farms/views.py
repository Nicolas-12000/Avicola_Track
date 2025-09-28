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

logger = logging.getLogger(__name__)


class FarmViewSet(viewsets.ModelViewSet):
    queryset = Farm.objects.all()
    serializer_class = FarmSerializer
    permission_classes = [permissions.IsAuthenticated]

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
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]

    @extend_schema(parameters=[OpenApiParameter(name='pk', required=True, type=OpenApiTypes.INT)])
    def retrieve(self, request, *args, **kwargs):
        return super().retrieve(request, *args, **kwargs)

    def get_queryset(self):
        user = self.request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        if role_name == 'Administrador Sistema':
            return Shed.objects.all()
        if role_name == 'Administrador de Granja':
            return Shed.objects.filter(farm__farm_manager=user)
        if role_name == 'Galponero':
            return Shed.objects.filter(assigned_worker=user)

        return Shed.objects.none()

