from django.core.management.base import BaseCommand
from apps.alarms.services import AlarmEvaluationEngine
from apps.alarms.models import AlarmConfiguration, Alarm


class Command(BaseCommand):
    help = 'Evaluate stock alarms for all farms'

    def handle(self, *args, **options):
        self.stdout.write('Evaluating stock alarms...')
        
        # Get all STOCK configurations
        configs = AlarmConfiguration.objects.filter(alarm_type='STOCK', is_active=True)
        
        if not configs.exists():
            self.stdout.write(self.style.WARNING('No active STOCK alarm configurations found'))
            return
        
        total_created = 0
        
        for config in configs:
            self.stdout.write(f'\nEvaluating farm: {config.farm.name}')
            try:
                created = AlarmEvaluationEngine._evaluate_stock_alarms(config.farm, config)
                total_created += created
                self.stdout.write(
                    self.style.SUCCESS(f'  Created {created} alarms')
                )
            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f'  Error: {e}')
                )
        
        # Show results
        self.stdout.write('\n' + '=' * 50)
        self.stdout.write(self.style.SUCCESS(f'Total alarms created: {total_created}'))
        
        # Show current alarms
        pending_alarms = Alarm.objects.filter(alarm_type='STOCK', status='PENDING')
        self.stdout.write(f'Total pending STOCK alarms: {pending_alarms.count()}')
        
        for alarm in pending_alarms:
            self.stdout.write(f'  - {alarm.description} ({alarm.priority})')
