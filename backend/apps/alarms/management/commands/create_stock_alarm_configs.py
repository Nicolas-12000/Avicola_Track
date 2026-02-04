from django.core.management.base import BaseCommand
from apps.farms.models import Farm
from apps.alarms.models import AlarmConfiguration


class Command(BaseCommand):
    help = 'Create default STOCK alarm configurations for all farms'

    def handle(self, *args, **options):
        farms = Farm.objects.all()
        created_count = 0
        
        for farm in farms:
            config, created = AlarmConfiguration.objects.get_or_create(
                farm=farm,
                alarm_type='STOCK',
                defaults={
                    'threshold_value': 0,  # Not used for STOCK alarms
                    'critical_threshold': None,
                    'evaluation_period_hours': 24,
                    'consecutive_occurrences': 1,
                    'notify_farm_manager': True,
                    'notify_veterinarian': False,
                    'notify_galponeros': True,
                    'escalate_after_hours': 24,
                    'escalate_to_admin': True,
                    'is_active': True,
                }
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created STOCK alarm config for farm: {farm.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'STOCK alarm config already exists for farm: {farm.name}')
                )
        
        self.stdout.write(
            self.style.SUCCESS(f'\nTotal created: {created_count} / {farms.count()}')
        )
