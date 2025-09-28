from django.db import transaction, models
from django.utils.dateparse import parse_date
from django.utils import timezone
from django.core.exceptions import ValidationError

from .models import MortalityRecord, MortalityCause, Flock


class MortalityService:
    @staticmethod
    def register_mortality_batch(mortality_records, user):
        """Registra múltiples mortalidades en batch (para sync offline)"""
        results = []

        with transaction.atomic():
            for record_data in mortality_records:
                try:
                    result = MortalityService._process_single_mortality(record_data, user)
                    results.append(result)
                except Exception as e:
                    results.append({
                        'client_id': record_data.get('client_id'),
                        'status': 'error',
                        'error': str(e)
                    })

        return results

    @staticmethod
    def _process_single_mortality(record_data, user):
        flock = Flock.objects.get(id=record_data['flock_id'])
        date = parse_date(record_data['date'])
        deaths = int(record_data['deaths'])

        # Validar permisos (Galponero solo en sus galpones)
        role_name = getattr(getattr(user, 'role', None), 'name', None)
        if role_name == 'Galponero' and flock.shed.assigned_worker != user:
            raise PermissionError("No tienes permisos para registrar mortalidad en este galpón")

        # Verificar duplicado del mismo día (sumar si existe)
        existing = MortalityRecord.objects.filter(flock=flock, date=date).first()

        if existing:
            # Sumar mortalidad al registro existente
            total_deaths = existing.deaths + deaths
            if total_deaths > (flock.current_quantity + existing.deaths):
                raise ValidationError("La mortalidad total excede la cantidad del lote")

            existing.deaths = total_deaths
            existing.save()  # Trigger actualización automática

            return {
                'client_id': record_data.get('client_id'),
                'status': 'success',
                'action': 'updated',
                'server_id': existing.id
            }

        # Crear nuevo registro
        cause = None
        if record_data.get('cause_name'):
            cause, _ = MortalityCause.objects.get_or_create(
                name=record_data['cause_name'],
                defaults={'category': 'OTHER'}
            )

        mortality_record = MortalityRecord.objects.create(
            flock=flock,
            date=date,
            deaths=deaths,
            cause=cause,
            temperature=record_data.get('temperature'),
            notes=record_data.get('notes', ''),
            recorded_by=user,
            client_id=record_data.get('client_id'),
            created_by_device=record_data.get('device_id')
        )

        return {
            'client_id': record_data.get('client_id'),
            'status': 'success',
            'action': 'created',
            'server_id': mortality_record.id
        }

    @staticmethod
    def calculate_mortality_stats(flock, days=7):
        """Calcula estadísticas de mortalidad de un lote"""
        from datetime import timedelta

        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)

        mortality_records = flock.mortality_records.filter(date__range=[start_date, end_date])

        total_deaths = mortality_records.aggregate(total=models.Sum('deaths'))['total'] or 0

        return {
            'total_deaths': total_deaths,
            'mortality_rate': (total_deaths / flock.initial_quantity) * 100 if flock.initial_quantity else 0,
            'daily_average': total_deaths / days,
            'worst_day': mortality_records.order_by('-deaths').first(),
            'period': f'{start_date} - {end_date}'
        }
