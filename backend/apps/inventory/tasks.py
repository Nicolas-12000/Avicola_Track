from celery import shared_task
from .models import InventoryItem


@shared_task
def update_all_inventory_metrics_task():
    """Actualizar métricas de consumo de todos los items de inventario"""
    items = InventoryItem.objects.all()
    updated_count = 0
    
    for item in items:
        try:
            item.update_consumption_metrics()
            updated_count += 1
        except Exception as e:
            # Log el error pero continúa con los demás items
            print(f"Error actualizando métricas de {item.name}: {str(e)}")
    
    return {
        'total_items': items.count(),
        'updated_items': updated_count
    }


@shared_task
def check_stock_alerts_task():
    """Verificar y generar alarmas por stock crítico"""
    from apps.alarms.models import AlarmConfiguration, Alarm
    
    critical_items = []
    
    # Obtener items con stock crítico
    for item in InventoryItem.objects.all():
        status = item.stock_status
        if status['status'] in ['CRITICAL', 'OUT_OF_STOCK']:
            critical_items.append(item)
            
            # Verificar configuración de alarmas de stock
            config = AlarmConfiguration.objects.filter(
                alarm_type='STOCK',
                farm=item.farm,
                is_active=True
            ).first()
            
            if config:
                # Verificar si no existe alarma similar reciente
                recent_alarms = Alarm.objects.filter(
                    alarm_type='STOCK',
                    entity_type='INVENTORY',
                    entity_id=item.id,
                    status='PENDING'
                )
                
                if not recent_alarms.exists():
                    priority = 'HIGH' if status['status'] == 'OUT_OF_STOCK' else 'MEDIUM'
                    
                    Alarm.objects.create(
                        alarm_type='STOCK',
                        entity_type='INVENTORY',
                        entity_id=item.id,
                        priority=priority,
                        title=f'Stock crítico - {item.name}',
                        message=f'{item.name} en {item.location_display}: {status["message"]}',
                        farm=item.farm,
                        shed=item.shed,
                        data={
                            'inventory_id': item.id,
                            'current_stock': float(item.current_stock),
                            'unit': item.unit,
                            'status': status['status'],
                            'projected_stockout': item.projected_stockout_date.isoformat() if item.projected_stockout_date else None
                        }
                    )
    
    return {
        'critical_items_count': len(critical_items),
        'alarms_generated': len([item for item in critical_items if AlarmConfiguration.objects.filter(alarm_type='STOCK', farm=item.farm, is_active=True).exists()])
    }