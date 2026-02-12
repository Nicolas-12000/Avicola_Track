from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from django.db import transaction

from .models import DispatchRecord, Flock
from .serializers_dispatch import DispatchRecordSerializer, DispatchRecordCreateSerializer
from .permissions import IsAssignedShedWorkerOrFarmAdmin
from .mixins import RoleFilteredMixin, RecordedByMixin


class DispatchRecordViewSet(RoleFilteredMixin, RecordedByMixin, viewsets.ModelViewSet):
    queryset = DispatchRecord.objects.all()
    serializer_class = DispatchRecordSerializer
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]

    def get_queryset(self):
        qs = DispatchRecord.objects.select_related('flock', 'flock__shed', 'flock__shed__farm').all()

        # Filtros
        flock_param = self.request.query_params.get('flock')
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')

        if flock_param:
            qs = qs.filter(flock_id=flock_param)
        if date_from:
            qs = qs.filter(dispatch_date__gte=date_from)
        if date_to:
            qs = qs.filter(dispatch_date__lte=date_to)

        return self.apply_role_filter(qs)

    def create(self, request, *args, **kwargs):
        """Crear registro de despacho con auto-cálculos"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            flock = serializer.validated_data['flock']

            # Autocompletar shed_name si no se proporcionó
            if not serializer.validated_data.get('shed_name'):
                serializer.validated_data['shed_name'] = flock.shed.name if flock.shed else ''

            # plant_birds auto-cálculo
            total = serializer.validated_data.get('total_birds', 0)
            drowned = serializer.validated_data.get('drowned', 0)
            missing = serializer.validated_data.get('plant_missing', 0)
            if not serializer.validated_data.get('plant_birds') and total:
                serializer.validated_data['plant_birds'] = total - drowned - missing

            self.perform_create(serializer)

        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        """Actualizar despacho - permite agregar datos de planta y venta después"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)

        # En update, no actualizar el lote de nuevo (ya se restaron los pollos)
        serializer.save(_skip_flock_update=True)
        return Response(serializer.data)
