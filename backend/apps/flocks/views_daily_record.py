from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import transaction
from django.db.models import Sum

from .models import DailyRecord, Flock
from .serializers_daily_record import (
    DailyRecordSerializer,
    DailyRecordCreateSerializer,
    BulkDailyRecordSyncSerializer,
)
from .permissions import IsAssignedShedWorkerOrFarmAdmin
from .mixins import RoleFilteredMixin, RecordedByMixin


class DailyRecordViewSet(RoleFilteredMixin, RecordedByMixin, viewsets.ModelViewSet):
    queryset = DailyRecord.objects.all()
    serializer_class = DailyRecordSerializer
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]

    def get_queryset(self):
        qs = DailyRecord.objects.select_related('flock', 'flock__shed', 'flock__shed__farm').all()

        # Filtros por query params
        flock_param = self.request.query_params.get('flock')
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        week = self.request.query_params.get('week')

        if flock_param:
            qs = qs.filter(flock_id=flock_param)
        if date_from:
            qs = qs.filter(date__gte=date_from)
        if date_to:
            qs = qs.filter(date__lte=date_to)
        if week:
            qs = qs.filter(week_number=week)

        return self.apply_role_filter(qs)

    @action(detail=False, methods=['post'], url_path='bulk-sync')
    def bulk_sync(self, request):
        """Sincronización masiva de registros diarios desde dispositivos offline"""
        bulk_serializer = BulkDailyRecordSyncSerializer(data=request.data)
        bulk_serializer.is_valid(raise_exception=True)

        results = []
        for record_data in bulk_serializer.validated_data['daily_records']:
            try:
                with transaction.atomic():
                    flock = Flock.objects.get(id=record_data['flock_id'])
                    date = record_data['date']

                    # Verificar si ya existe
                    existing = DailyRecord.objects.filter(flock=flock, date=date).first()
                    if existing:
                        results.append({
                            'client_id': record_data.get('client_id', ''),
                            'server_id': existing.id,
                            'status': 'exists',
                            'message': 'Already exists for this date',
                        })
                        continue

                    # Calcular saldo (tomar del último registro o del lote)
                    prev_record = DailyRecord.objects.filter(
                        flock=flock, date__lt=date
                    ).order_by('-date').first()

                    if prev_record:
                        prev_male = prev_record.balance_male
                        prev_female = prev_record.balance_female
                        prev_accum_male = float(prev_record.accumulated_feed_per_bird_gr_male or 0)
                        prev_accum_female = float(prev_record.accumulated_feed_per_bird_gr_female or 0)
                        prev_weight_male = float(prev_record.weight_male) if prev_record.weight_male else None
                        prev_weight_female = float(prev_record.weight_female) if prev_record.weight_female else None
                    else:
                        prev_male = flock.current_quantity_male
                        prev_female = flock.current_quantity_female
                        prev_accum_male = 0
                        prev_accum_female = 0
                        prev_weight_male = float(flock.initial_weight_male or flock.initial_weight or 0)
                        prev_weight_female = float(flock.initial_weight_female or flock.initial_weight or 0)

                    balance_male = prev_male - record_data.get('mortality_male', 0) - record_data.get('process_output_male', 0)
                    balance_female = prev_female - record_data.get('mortality_female', 0) - record_data.get('process_output_female', 0)

                    # Calcular consumo por pollo y acumulado
                    feed_per_bird_male = 0
                    feed_per_bird_female = 0
                    if balance_male > 0 and record_data.get('feed_consumed_kg_male', 0) > 0:
                        feed_per_bird_male = (float(record_data['feed_consumed_kg_male']) * 1000) / balance_male
                    if balance_female > 0 and record_data.get('feed_consumed_kg_female', 0) > 0:
                        feed_per_bird_female = (float(record_data['feed_consumed_kg_female']) * 1000) / balance_female

                    accum_male = prev_accum_male + feed_per_bird_male
                    accum_female = prev_accum_female + feed_per_bird_female

                    # Calcular ganancia de peso
                    weight_male = record_data.get('weight_male')
                    weight_female = record_data.get('weight_female')

                    # Ganancia peso semanal (comparar con registro de hace 7 días)
                    weekly_gain_male = None
                    weekly_gain_female = None
                    daily_gain_male = None
                    daily_gain_female = None

                    from datetime import timedelta
                    week_ago_record = DailyRecord.objects.filter(
                        flock=flock, date=date - timedelta(days=7)
                    ).first()

                    if weight_male is not None:
                        if week_ago_record and week_ago_record.weight_male:
                            weekly_gain_male = float(weight_male) - float(week_ago_record.weight_male)
                        if prev_weight_male is not None:
                            daily_gain_male = float(weight_male) - prev_weight_male

                    if weight_female is not None:
                        if week_ago_record and week_ago_record.weight_female:
                            weekly_gain_female = float(weight_female) - float(week_ago_record.weight_female)
                        if prev_weight_female is not None:
                            daily_gain_female = float(weight_female) - prev_weight_female

                    daily_record = DailyRecord.objects.create(
                        flock=flock,
                        date=date,
                        week_number=0,  # se calcula en save()
                        day_number=0,   # se calcula en save()
                        mortality_male=record_data.get('mortality_male', 0),
                        mortality_female=record_data.get('mortality_female', 0),
                        process_output_male=record_data.get('process_output_male', 0),
                        process_output_female=record_data.get('process_output_female', 0),
                        balance_male=max(0, balance_male),
                        balance_female=max(0, balance_female),
                        feed_consumed_kg_male=record_data.get('feed_consumed_kg_male', 0),
                        feed_consumed_kg_female=record_data.get('feed_consumed_kg_female', 0),
                        accumulated_feed_per_bird_gr_male=accum_male,
                        accumulated_feed_per_bird_gr_female=accum_female,
                        weight_male=weight_male,
                        weight_female=weight_female,
                        weekly_weight_gain_male=weekly_gain_male,
                        weekly_weight_gain_female=weekly_gain_female,
                        daily_avg_weight_gain_male=daily_gain_male,
                        daily_avg_weight_gain_female=daily_gain_female,
                        temperature=record_data.get('temperature'),
                        notes=record_data.get('notes', ''),
                        recorded_by=request.user,
                        client_id=record_data.get('client_id'),
                    )

                    results.append({
                        'client_id': record_data.get('client_id', ''),
                        'server_id': daily_record.id,
                        'status': 'created',
                        'message': 'OK',
                    })

            except Flock.DoesNotExist:
                results.append({
                    'client_id': record_data.get('client_id', ''),
                    'status': 'error',
                    'message': f'Flock {record_data["flock_id"]} not found',
                })
            except Exception as e:
                results.append({
                    'client_id': record_data.get('client_id', ''),
                    'status': 'error',
                    'message': str(e),
                })

        total = len(results)
        success = sum(1 for r in results if r['status'] in ('created', 'exists'))
        errors = sum(1 for r in results if r['status'] == 'error')

        return Response({
            'total': total,
            'successful': success,
            'errors': errors,
            'details': results,
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'], url_path='summary')
    def summary(self, request):
        """Obtener resumen consolidado (totales machos+hembras) para un lote"""
        flock_id = request.query_params.get('flock')
        if not flock_id:
            return Response({'detail': 'flock param required'}, status=status.HTTP_400_BAD_REQUEST)

        records = DailyRecord.objects.filter(flock_id=flock_id).order_by('date')

        data = []
        for r in records:
            data.append({
                'date': r.date.isoformat(),
                'week': r.week_number,
                'day': r.day_number,
                'mortality_total': (r.mortality_male or 0) + (r.mortality_female or 0),
                'process_output_total': (r.process_output_male or 0) + (r.process_output_female or 0),
                'balance_total': (r.balance_male or 0) + (r.balance_female or 0),
                'feed_consumed_kg_total': float(r.feed_consumed_kg_male or 0) + float(r.feed_consumed_kg_female or 0),
                'weight_avg': (
                    (float(r.weight_male or 0) + float(r.weight_female or 0)) / 2
                    if r.weight_male and r.weight_female
                    else float(r.weight_male or r.weight_female or 0)
                ),
                'feed_conversion_avg': (
                    (float(r.feed_conversion_male or 0) + float(r.feed_conversion_female or 0)) / 2
                    if r.feed_conversion_male and r.feed_conversion_female
                    else float(r.feed_conversion_male or r.feed_conversion_female or 0)
                ),
            })

        return Response(data)
