from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiResponse
from django.utils.dateparse import parse_date
from decimal import Decimal
from django.utils import timezone
from django.views.decorators.cache import cache_page
from django.utils.decorators import method_decorator

from .models import DailyWeightRecord, BreedReference
from .models import SyncConflict
from .serializers_weight import (
    DailyWeightSerializer,
    BreedReferenceSerializer,
    BulkSyncRequestSerializer,
    BulkSyncResultSerializer,
    DashboardResponseSerializer,
)
from drf_spectacular.utils import OpenApiExample
from apps.farms.models import Shed


class DailyWeightViewSet(viewsets.ModelViewSet):
    queryset = DailyWeightRecord.objects.all()
    serializer_class = DailyWeightSerializer

    @extend_schema(
        description='Sincroniza en bloque registros de peso promedio desde dispositivos móviles. Devuelve un resumen con detalles por client_id indicando si se creó, se promedió o se reportó conflicto.',
        request=BulkSyncRequestSerializer,
        responses=OpenApiResponse(response=BulkSyncResultSerializer),
        examples=[
            OpenApiExample(
                'Ejemplo éxito parcial',
                value={
                    'total': 2,
                    'successful': 1,
                    'conflicts': 1,
                    'errors': 0,
                    'details': [
                        {'client_id': 'c1', 'server_id': 123, 'status': 'created', 'message': ''},
                        {'client_id': 'c2', 'server_id': None, 'status': 'conflict', 'message': 'manual_conflict_required'}
                    ]
                }
            )
        ]
    )
    @action(detail=False, methods=['post'], url_path='bulk-sync')
    def bulk_sync_weights(self, request):
        device_id = request.META.get('HTTP_X_DEVICE_ID', 'unknown')
        weight_records = request.data.get('weight_records', [])

        sync_results = {
            'total': len(weight_records),
            'successful': 0,
            'conflicts': 0,
            'errors': 0,
            'details': []
        }

        for record_data in weight_records:
            try:
                result = self._process_weight_sync(record_data, request.user, device_id)
                sync_results[result['status']] += 1
                sync_results['details'].append(result)
            except Exception as e:
                sync_results['errors'] += 1
                sync_results['details'].append({
                    'client_id': record_data.get('client_id'),
                    'status': 'error',
                    'error': str(e)
                })

        return Response(sync_results)

    def _process_weight_sync(self, record_data, user, device_id):
        flock_id = record_data['flock_id']
        date = parse_date(record_data['date'])
        weight = Decimal(record_data['average_weight'])
        client_id = record_data.get('client_id')

        existing = DailyWeightRecord.objects.filter(flock_id=flock_id, date=date).first()
        if existing:
            if abs(existing.average_weight - weight) < Decimal('50'):
                new_weight = (existing.average_weight + weight) / 2
                existing.average_weight = new_weight
                existing.sync_status = 'SYNCED'
                existing.save()
                return {
                    'client_id': client_id,
                    'status': 'successful',
                    'resolution': 'averaged',
                    'server_id': existing.id
                }
            else:
                # Persist conflict for manual resolution
                conflict = SyncConflict.objects.create(
                    source='daily_weight',
                    client_id=client_id,
                    payload={
                        'flock_id': flock_id,
                        'date': date.isoformat(),
                        'existing_server_weight': str(existing.average_weight),
                        'incoming_weight': str(weight),
                    },
                    flock_id=flock_id
                )

                return {
                    'client_id': client_id,
                    'status': 'conflicts',
                    'error': 'manual_conflict_required',
                    'server_conflict_id': conflict.id
                }

        weight_record = DailyWeightRecord.objects.create(
            flock_id=flock_id,
            date=date,
            average_weight=weight,
            sample_size=record_data.get('sample_size', 10),
            recorded_by=user,
            client_id=client_id,
            created_by_device=device_id
        )

        # Placeholder for alarms check
        # self._check_weight_alarms(weight_record)

        return {
            'client_id': client_id,
            'status': 'successful',
            'server_id': weight_record.id
        }


class ShedDashboardView(APIView):
    @method_decorator(cache_page(120))
    @extend_schema(
        description='Vista resumida del estado de los galpones accesibles al usuario. Incluye resumen de capacidad/ocupación, listado de galpones con indicadores y la hora del último cálculo.',
        responses=OpenApiResponse(response=DashboardResponseSerializer),
        examples=[
            OpenApiExample(
                'Ejemplo dashboard',
                value={
                    'summary': {'total_capacity': 1000, 'total_occupancy': 560},
                    'sheds': [
                        {
                            'id': 1,
                            'name': 'Galpón A',
                            'farm_name': 'Granja Central',
                            'galponero': 'Juan Perez',
                            'occupancy': {'current': 200, 'capacity': 300, 'percentage': 66.67},
                            'flocks': {'active_count': 2, 'avg_age': 15.5, 'total_birds': 200},
                            'last_activity': {'weight_date': '2025-09-28'},
                            'status_indicator': {'color': 'green', 'message': 'Al día'}
                        }
                    ],
                    'alerts_count': 3,
                    'last_updated': '2025-09-28T12:00:00Z'
                }
            )
        ]
    )
    def get(self, request):
        user = request.user
        accessible_sheds = self._get_accessible_sheds(user)

        dashboard_data = {
            'summary': self._calculate_farm_summary(accessible_sheds),
            'sheds': self._get_sheds_detail(accessible_sheds),
            'alerts_count': self._count_pending_alerts(accessible_sheds),
            'last_updated': timezone.now().isoformat()
        }

        return Response(dashboard_data)

    def _get_accessible_sheds(self, user):
        # Prefer role name when available, but fall back to id-based checks
        role = getattr(user, 'role', None)
        role_name = getattr(role, 'name', None) if role else None

        if role_name == 'Administrador Sistema' or getattr(user, 'is_superuser', False):
            return Shed.objects.all()

        if role_name == 'Administrador de Granja':
            return Shed.objects.filter(farm__farm_manager_id=user.id)

        if role_name == 'Galponero':
            return Shed.objects.filter(assigned_worker_id=user.id)

        # Fall back: if the user appears as a farm manager in any farm, return those sheds
        from apps.farms.models import Farm
        if Farm.objects.filter(farm_manager_id=user.id).exists():
            return Shed.objects.filter(farm__farm_manager_id=user.id)

        # Fall back: if user is assigned as worker to any shed
        if Shed.objects.filter(assigned_worker_id=user.id).exists():
            return Shed.objects.filter(assigned_worker_id=user.id)

        return Shed.objects.none()

    def _calculate_farm_summary(self, sheds):
        total_capacity = sum(s.capacity for s in sheds)
        total_occupancy = sum(s.current_occupancy for s in sheds)
        return {'total_capacity': total_capacity, 'total_occupancy': total_occupancy}

    def _get_sheds_detail(self, sheds):
        sheds_data = []
        for shed in sheds:
            active_flocks = shed.flocks.filter(status='ACTIVE')
            last_weight = shed.weight_records.order_by('-date').first() if hasattr(shed, 'weight_records') else None
            last_mortality = None
            sheds_data.append({
                'id': shed.id,
                'name': shed.name,
                'farm_name': shed.farm.name,
                'galponero': shed.assigned_worker.get_full_name() if shed.assigned_worker else 'Sin asignar',
                'occupancy': {
                    'current': shed.current_occupancy,
                    'capacity': shed.capacity,
                    'percentage': shed.occupancy_percentage
                },
                'flocks': {
                    'active_count': active_flocks.count(),
                    'avg_age': sum(f.current_age_days for f in active_flocks) / (active_flocks.count() or 1),
                    'total_birds': sum(f.current_quantity for f in active_flocks)
                },
                'last_activity': {
                    'weight_date': last_weight.date if last_weight else None,
                },
                'status_indicator': self._get_status_indicator(shed, last_weight)
            })

        return sheds_data

    def _count_pending_alerts(self, sheds):
        """
        Placeholder implementation: count weight records with a significant deviation
        or other pending alerts. For now return 0 or a simple computation to keep
        the endpoint stable. This can be extended later to include mortality,
        weight deviations, or manual alerts.
        """
        try:
            # Example: count weight records with deviation > 10% in the last 7 days
            from datetime import timedelta
            from .models import DailyWeightRecord
            cutoff = timezone.now().date() - timedelta(days=7)
            shed_ids = [s.id for s in sheds]
            return DailyWeightRecord.objects.filter(flock__shed_id__in=shed_ids, date__gte=cutoff, deviation_percentage__gt=10).count()
        except Exception:
            return 0

    def _get_status_indicator(self, shed, last_weight):
        today = timezone.now().date()
        if not last_weight:
            return {'color': 'orange', 'message': 'Sin registros'}
        if last_weight.date == today:
            return {'color': 'green', 'message': 'Al día'}
        if last_weight.date == today - timezone.timedelta(days=1):
            return {'color': 'yellow', 'message': 'Pendiente registro'}
        return {'color': 'red', 'message': 'Registros atrasados'}
