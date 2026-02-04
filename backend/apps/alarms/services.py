import logging
from django.utils import timezone
from django.db import models

from apps.farms.models import Farm

from .models import AlarmConfiguration, Alarm

logger = logging.getLogger(__name__)


class AlarmEvaluationEngine:
    @staticmethod
    def evaluate_all_farms():
        active_farms = Farm.objects.filter(alarm_configs__is_active=True).distinct()
        results = {'farms_evaluated': 0, 'alarms_generated': 0, 'errors': 0}

        for farm in active_farms:
            try:
                res = AlarmEvaluationEngine.evaluate_farm(farm)
                results['farms_evaluated'] += 1
                results['alarms_generated'] += res.get('alarms_created', 0)
            except Exception as e:
                results['errors'] += 1
                logger.exception(e)

        return results

    @staticmethod
    def evaluate_farm(farm: Farm):
        configs = farm.alarm_configs.filter(is_active=True)
        alarms_created = 0

        for config in configs:
            try:
                if config.alarm_type == 'MORTALITY':
                    created = AlarmEvaluationEngine._evaluate_mortality_alarms(farm, config)
                elif config.alarm_type == 'NO_RECORDS':
                    created = AlarmEvaluationEngine._evaluate_missing_records_alarms(farm, config)
                elif config.alarm_type == 'STOCK':
                    created = AlarmEvaluationEngine._evaluate_stock_alarms(farm, config)
                else:
                    created = 0

                alarms_created += created
            except Exception:
                logger.exception('Error evaluating config %s', config.id)

        return {'alarms_created': alarms_created}

    @staticmethod
    def _evaluate_mortality_alarms(farm: Farm, config: AlarmConfiguration):
        """Evaluate recent mortality records for the farm and create alarms when
        daily mortality rate for a flock exceeds the configured threshold.

        Behavior:
        - look back over the config.evaluation_period_hours window (rounded to days)
        - for each flock in the farm, examine MortalityRecord entries in that window
        - compute daily mortality rate for each record and compare to config.threshold_value
        - create an Alarm for each offending MortalityRecord unless an unresolved
          Alarm for the same flock and day already exists (avoid duplicates)
        - set priority to HIGH if exceeds critical_threshold (if set)
        - call AlarmNotificationService.send_alarm_notifications for created alarms

        Returns number of alarms created.
        """
        from datetime import timedelta
        from apps.flocks.models import MortalityRecord, Flock
        created = 0

        # convert hours window to days (at least 1)
        hours = max(1, config.evaluation_period_hours)
        days = max(1, int((hours + 23) // 24))
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)

        flocks = Flock.objects.filter(shed__farm=farm)
        for flock in flocks:
            records = MortalityRecord.objects.filter(flock=flock, date__range=[start_date, end_date])
            for rec in records:
                try:
                    original_quantity = rec.flock.current_quantity + rec.deaths
                    if original_quantity == 0:
                        continue

                    daily_mortality_rate = (rec.deaths / original_quantity) * 100

                    if daily_mortality_rate >= float(config.threshold_value):
                        # avoid duplicate unresolved alarms for same source (structured)
                        exists = Alarm.objects.filter(
                            alarm_type='MORTALITY',
                            source_type='mortality',
                            source_date=rec.date,
                            source_id=rec.id,
                        ).exclude(status='RESOLVED').exists()

                        if exists:
                            continue

                        priority = 'HIGH' if (config.critical_threshold and daily_mortality_rate >= float(config.critical_threshold)) else 'MEDIUM'

                        alarm = Alarm.objects.create(
                            alarm_type='MORTALITY',
                            description=f'Mortalidad alta en {flock.shed.name} - {rec.date}: {daily_mortality_rate:.1f}% (umbral: {config.threshold_value}%)',
                            priority=priority,
                            farm=farm,
                            flock=flock,
                            configuration=config,
                            source_type='mortality',
                            source_date=rec.date,
                            source_id=rec.id,
                        )

                        created += 1

                        try:
                            AlarmNotificationService.send_alarm_notifications(alarm, config)
                        except Exception:
                            logger.exception('Failed sending notifications for alarm %s', alarm.id)
                except Exception:
                    logger.exception('Error evaluating mortality record %s', rec.id)

        return created

    @staticmethod
    def _evaluate_missing_records_alarms(farm: Farm, config: AlarmConfiguration):
        # Placeholder implementation
        return 0

    @staticmethod
    def _evaluate_stock_alarms(farm: Farm, config: AlarmConfiguration):
        """Evaluate inventory items for low/critical stock and create alarms.
        
        Behavior:
        - Check all inventory items for the farm
        - Create alarms for items with CRITICAL or LOW stock status
        - Update existing unresolved alarms if status changed
        - Set priority based on stock status (CRITICAL = HIGH, LOW = MEDIUM)
        
        Returns number of alarms created.
        """
        from apps.inventory.models import InventoryItem
        created = 0
        
        inventory_items = InventoryItem.objects.filter(farm=farm)
        
        for item in inventory_items:
            try:
                status_info = item.stock_status
                status = status_info['status']
                
                # Verificar si hay alarma existente no resuelta
                existing_alarm = Alarm.objects.filter(
                    alarm_type='STOCK',
                    inventory_item=item,
                    status__in=['PENDING', 'ESCALATED']
                ).first()
                
                # Si el estado es normal y hay alarma existente, resolverla
                if status not in ['CRITICAL', 'LOW', 'OUT_OF_STOCK']:
                    if existing_alarm:
                        existing_alarm.status = 'RESOLVED'
                        existing_alarm.save(update_fields=['status'])
                        logger.info(f"Auto-resolved STOCK alarm for {item.name} - status is now {status}")
                    continue
                
                # Si ya existe una alarma pendiente, actualizarla
                if existing_alarm:
                    # Actualizar descripción y prioridad si cambiaron
                    if status == 'OUT_OF_STOCK':
                        new_priority = 'URGENT'
                        new_description = f'Stock agotado: {item.name} en {item.location_display}'
                    elif status == 'CRITICAL':
                        new_priority = 'HIGH'
                        new_description = f'Stock crítico: {item.name} en {item.location_display} - {status_info["message"]}'
                    else:  # LOW
                        new_priority = 'MEDIUM'
                        new_description = f'Stock bajo: {item.name} en {item.location_display} - {status_info["message"]}'
                    
                    if existing_alarm.description != new_description or existing_alarm.priority != new_priority:
                        existing_alarm.description = new_description
                        existing_alarm.priority = new_priority
                        existing_alarm.source_date = timezone.now().date()
                        existing_alarm.save(update_fields=['description', 'priority', 'source_date'])
                        logger.info(f"Updated existing STOCK alarm for {item.name}")
                    continue
                
                # Crear nueva alarma
                if status == 'OUT_OF_STOCK':
                    priority = 'URGENT'
                    description = f'Stock agotado: {item.name} en {item.location_display}'
                elif status == 'CRITICAL':
                    priority = 'HIGH'
                    description = f'Stock crítico: {item.name} en {item.location_display} - {status_info["message"]}'
                else:  # LOW
                    priority = 'MEDIUM'
                    description = f'Stock bajo: {item.name} en {item.location_display} - {status_info["message"]}'
                
                alarm = Alarm.objects.create(
                    alarm_type='STOCK',
                    description=description,
                    priority=priority,
                    farm=farm,
                    inventory_item=item,
                    configuration=config,
                    source_type='inventory',
                    source_date=timezone.now().date(),
                    source_id=item.id,
                )
                
                created += 1
                logger.info(f"Created new STOCK alarm for {item.name}")
                
                try:
                    AlarmNotificationService.send_alarm_notifications(alarm, config)
                except Exception:
                    logger.exception('Failed sending notifications for alarm %s', alarm.id)
                    
            except Exception:
                logger.exception('Error evaluating inventory item %s', item.id)
        
        return created


class AlarmNotificationService:
    @staticmethod
    def send_alarm_notifications(alarm: Alarm, config: AlarmConfiguration):
        from .notifications import get_default_adapter

        adapter = get_default_adapter()
        recipients = config.get_notification_recipients()
        results = []
        for r in recipients:
            try:
                res = adapter.send(alarm, r)
                results.append(res)
            except Exception:
                logger.exception('Adapter failed for recipient %s', getattr(r, 'id', r))

        return results

    @staticmethod
    def send_direct_notification(alarm: Alarm, recipient, adapter_name=None):
        # helper to send to a single recipient with optional adapter override
        from .notifications import get_default_adapter, LocalFallbackAdapter, FCMAdapter, EmailAdapter

        if adapter_name == 'fcm':
            adapter = FCMAdapter()
        elif adapter_name == 'email':
            adapter = EmailAdapter()
        else:
            adapter = get_default_adapter()

        try:
            return adapter.send(alarm, recipient)
        except Exception:
            logger.exception('Direct send failed')
            return {'status': 'error'}


# re-export escalation service for tasks import
try:
    from .escalation import AlarmEscalationService  # type: ignore
except Exception:
    AlarmEscalationService = None
