from rest_framework import viewsets, permissions
from .models import AlarmConfiguration, Alarm, AlarmEscalation, NotificationLog
from .serializers import AlarmConfigurationSerializer, AlarmSerializer
from .serializers_notifications import NotificationLogSerializer


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
        """Filtrado inteligente de alarmas por rol y parámetros de query"""
        user = self.request.user

        role_name = getattr(user.role, 'name', None)

        if role_name == 'Administrador Sistema':
            queryset = Alarm.objects.all()
        elif role_name == 'Administrador de Granja':
            queryset = Alarm.objects.filter(
                dj_models.Q(flock__shed__farm__farm_manager=user) |
                dj_models.Q(inventory_item__farm__farm_manager=user) |
                dj_models.Q(shed__farm__farm_manager=user) |
                dj_models.Q(farm__farm_manager=user)
            )
        elif role_name == 'Galponero':
            queryset = Alarm.objects.filter(
                dj_models.Q(flock__shed__assigned_worker=user) |
                dj_models.Q(shed__assigned_worker=user)
            )
        elif role_name == 'Veterinario':
            assigned_farms = getattr(user, 'assigned_farms', None)
            if assigned_farms is not None:
                queryset = Alarm.objects.filter(
                    dj_models.Q(flock__shed__farm__in=assigned_farms.all()) |
                    dj_models.Q(inventory_item__farm__in=assigned_farms.all()) |
                    dj_models.Q(shed__farm__in=assigned_farms.all()) |
                    dj_models.Q(farm__in=assigned_farms.all())
                )
            else:
                queryset = Alarm.objects.none()
        else:
            queryset = Alarm.objects.none()

        # Aplicar filtro de farm si se proporciona
        farm_id = self.request.query_params.get('farm')
        if farm_id:
            queryset = queryset.filter(farm_id=farm_id)
        
        # Aplicar filtro de is_resolved si se proporciona
        is_resolved = self.request.query_params.get('is_resolved')
        if is_resolved is not None:
            if is_resolved.lower() == 'true':
                queryset = queryset.filter(status='RESOLVED')
            elif is_resolved.lower() == 'false':
                queryset = queryset.exclude(status='RESOLVED')
        
        # Aplicar filtro de severity/priority si se proporciona
        severity = self.request.query_params.get('severity')
        if severity:
            # Mapear severity del frontend a priority del backend
            severity_to_priority = {
                'critical': 'URGENT',
                'high': 'HIGH',
                'medium': 'MEDIUM',
                'low': 'LOW',
            }
            priority = severity_to_priority.get(severity.lower())
            if priority:
                queryset = queryset.filter(priority=priority)
        
        return queryset.order_by('-created_at')

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Dashboard de alarmas con métricas"""
        user_alarms = self.get_queryset()

        stats = user_alarms.aggregate(
            total=Count('id'),
            pending=Count('id', filter=dj_models.Q(status='PENDING')),
            resolved=Count('id', filter=dj_models.Q(status='RESOLVED')),
            escalated=Count('id', filter=dj_models.Q(status='ESCALATED')),
        )

        priority_stats = user_alarms.filter(status='PENDING').aggregate(
            critical=Count('id', filter=dj_models.Q(priority='URGENT')),
            high=Count('id', filter=dj_models.Q(priority='HIGH')),
            medium=Count('id', filter=dj_models.Q(priority='MEDIUM')),
            low=Count('id', filter=dj_models.Q(priority='LOW')),
        )

        type_stats = list(user_alarms.filter(status='PENDING').values('alarm_type').annotate(count=Count('id')).order_by('-count'))

        urgent_alarms = user_alarms.filter(status='PENDING').order_by(
            dj_models.Case(
                dj_models.When(priority='URGENT', then=0),
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

        alarm.status = 'RESOLVED'
        alarm.save(update_fields=['status'])

        logger.info(f"Alarm {alarm.id} resolved by {request.user.username}")

        return Response({'message': 'Alarma resuelta'})

    @action(detail=False, methods=['post'], url_path='bulk-acknowledge')
    def bulk_acknowledge(self, request):
        """Atender múltiples alarmas (para sync offline)"""
        alarm_ids = request.data.get('alarm_ids', [])
        notes = request.data.get('notes', '')

        user_alarms = self.get_queryset()
        alarms_to_update = user_alarms.filter(id__in=alarm_ids, status='PENDING')

        updated_count = alarms_to_update.update(status='RESOLVED')

        return Response({'updated_count': updated_count, 'message': f'{updated_count} alarmas resueltas'})

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        """Resolver alarma manualmente"""
        alarm = self.get_object()

        if alarm.status != 'PENDING':
            return Response({'error': 'Solo se pueden resolver alarmas pendientes'}, status=400)

        alarm.status = 'RESOLVED'
        alarm.save(update_fields=['status'])

        logger.info(f"Alarm {alarm.id} resolved by {request.user.username}")

        # Devolver la alarma actualizada para que el frontend pueda actualizarla
        serializer = self.get_serializer(alarm)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def escalate(self, request, pk=None):
        """Escalar alarma manualmente"""
        alarm = self.get_object()

        if alarm.status != 'PENDING':
            return Response({'error': 'Solo se pueden escalar alarmas pendientes'}, status=400)

        alarm.status = 'ESCALATED'
        alarm.save(update_fields=['status'])

        AlarmEscalation.objects.create(
            alarm=alarm,
            escalated_to=request.user,
            escalation_reason=request.data.get('reason', 'manual'),
        )

        logger.info(f"Alarm {alarm.id} escalated by {request.user.username}")

        # Devolver la alarma actualizada
        serializer = self.get_serializer(alarm)
        return Response(serializer.data)


class NotificationLogViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet para consultar notificaciones del usuario autenticado"""
    serializer_class = NotificationLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Solo notificaciones del usuario actual"""
        return NotificationLog.objects.filter(
            recipient=self.request.user
        ).select_related('alarm', 'recipient').order_by('-created_at')
    
    @action(detail=False, methods=['get'])
    def unread(self, request):
        """Obtener notificaciones no leídas (creadas en últimas 24h)"""
        from datetime import timedelta
        
        cutoff_time = timezone.now() - timedelta(hours=24)
        notifications = self.get_queryset().filter(
            created_at__gte=cutoff_time,
            status='SENT'
        )
        
        serializer = self.get_serializer(notifications, many=True)
        return Response({
            'count': notifications.count(),
            'notifications': serializer.data
        })
    
    @action(detail=False, methods=['get'])
    def recent(self, request):
        """Obtener notificaciones recientes (últimos 7 días)"""
        from datetime import timedelta
        
        cutoff_time = timezone.now() - timedelta(days=7)
        notifications = self.get_queryset().filter(
            created_at__gte=cutoff_time
        )[:50]  # Límite de 50
        
        serializer = self.get_serializer(notifications, many=True)
        return Response({
            'count': notifications.count(),
            'notifications': serializer.data
        })

