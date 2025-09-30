from rest_framework import viewsets, permissions
from .models import AlarmConfiguration, Alarm
from .serializers import AlarmConfigurationSerializer, AlarmSerializer


class AlarmConfigurationViewSet(viewsets.ModelViewSet):
    queryset = AlarmConfiguration.objects.all()
    serializer_class = AlarmConfigurationSerializer
    permission_classes = [permissions.IsAuthenticated]


class AlarmViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Alarm.objects.all().order_by('-created_at')
    serializer_class = AlarmSerializer
    permission_classes = [permissions.IsAuthenticated]
    
from django.shortcuts import render
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django import db
from django.db import models as dj_models
from django.db.models import Count
import logging

logger = logging.getLogger(__name__)


class AlarmManagementViewSet(viewsets.ModelViewSet):
    """ViewSet completo para gestión de alarmas"""
    queryset = Alarm.objects.all().order_by('-created_at')
    serializer_class = AlarmSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Filtrado inteligente de alarmas por rol"""
        user = self.request.user

        role_name = getattr(user.role, 'name', None)

        if role_name == 'Administrador Sistema':
            return Alarm.objects.all()
        elif role_name == 'Administrador de Granja':
            return Alarm.objects.filter(
                dj_models.Q(flock__shed__farm__farm_manager=user) |
                dj_models.Q(inventory_item__farm__farm_manager=user) |
                dj_models.Q(shed__farm__farm_manager=user)
            )
        elif role_name == 'Galponero':
            return Alarm.objects.filter(
                dj_models.Q(flock__shed__assigned_worker=user) |
                dj_models.Q(shed__assigned_worker=user)
            )
        elif role_name == 'Veterinario':
            assigned_farms = getattr(user, 'assigned_farms', None)
            if assigned_farms is not None:
                return Alarm.objects.filter(
                    dj_models.Q(flock__shed__farm__in=assigned_farms.all()) |
                    dj_models.Q(inventory_item__farm__in=assigned_farms.all()) |
                    dj_models.Q(shed__farm__in=assigned_farms.all())
                )

        return Alarm.objects.none()

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Dashboard de alarmas con métricas"""
        user_alarms = self.get_queryset()

        stats = user_alarms.aggregate(
            total=Count('id'),
            pending=Count('id', filter=dj_models.Q(status='PENDING')),
            acknowledged=Count('id', filter=dj_models.Q(status='ACKNOWLEDGED')),
        )

        priority_stats = user_alarms.filter(status='PENDING').aggregate(
            high=Count('id', filter=dj_models.Q(priority='HIGH')),
            medium=Count('id', filter=dj_models.Q(priority='MEDIUM')),
            low=Count('id', filter=dj_models.Q(priority='LOW')),
        )

        type_stats = list(user_alarms.filter(status='PENDING').values('alarm_type').annotate(count=Count('id')).order_by('-count'))

        urgent_alarms = self.get_queryset().filter(status='PENDING').order_by(
            dj_models.Case(
                dj_models.When(priority='HIGH', then=1),
                dj_models.When(priority='MEDIUM', then=2),
                dj_models.When(priority='LOW', then=3),
                default=4,
                output_field=dj_models.IntegerField(),
            ),
            'created_at'
        )[:10]

        return Response({
            'summary': {
                **stats,
                'priority_breakdown': priority_stats,
                'type_breakdown': type_stats,
            },
            'urgent_alarms': AlarmSerializer(urgent_alarms, many=True).data,
            'last_updated': timezone.now().isoformat()
        })

    @action(detail=True, methods=['post'])
    def acknowledge(self, request, pk=None):
        """Marcar alarma como atendida"""
        alarm = self.get_object()

        if alarm.status != 'PENDING':
            return Response({'error': 'Solo se pueden atender alarmas pendientes'}, status=400)

        alarm.status = 'ACKNOWLEDGED'
        alarm.acknowledged_by = request.user
        alarm.acknowledged_at = timezone.now()
        alarm.resolution_notes = request.data.get('notes', '')
        alarm.save()

        logger.info(f"Alarm {alarm.id} acknowledged by {request.user.username}")

        return Response({'message': 'Alarma marcada como atendida', 'acknowledged_at': alarm.acknowledged_at.isoformat()})

    @action(detail=False, methods=['post'], url_path='bulk-acknowledge')
    def bulk_acknowledge(self, request):
        """Atender múltiples alarmas (para sync offline)"""
        alarm_ids = request.data.get('alarm_ids', [])
        notes = request.data.get('notes', '')

        user_alarms = self.get_queryset()
        alarms_to_update = user_alarms.filter(id__in=alarm_ids, status='PENDING')

        updated_count = alarms_to_update.update(
            status='ACKNOWLEDGED',
            acknowledged_by=request.user,
            acknowledged_at=timezone.now(),
            resolution_notes=notes
        )

        return Response({'updated_count': updated_count, 'message': f'{updated_count} alarmas atendidas'})
