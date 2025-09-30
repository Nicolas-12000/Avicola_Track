import os
from celery import Celery

# Establecer el módulo de configuración por defecto de Django para el programa 'celery'.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'avicolatrack.settings')

app = Celery('avicolatrack')

# Usar una cadena aquí significa que el trabajador no tiene que serializar
# el objeto de configuración a los procesos hijos.
# namespace='CELERY' significa que todas las claves de configuración relacionadas con celery
# deberían tener un prefijo `CELERY_`.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Cargar módulos de tareas de todas las aplicaciones Django registradas.
app.autodiscover_tasks()

# Configuración de tareas programadas
app.conf.beat_schedule = {
    'evaluate-alarms-every-hour': {
        'task': 'apps.alarms.tasks.evaluate_all_alarms_task',
        'schedule': 3600.0,  # Cada hora en segundos
    },
    'escalate-alarms-every-4-hours': {
        'task': 'apps.alarms.tasks.escalate_unresolved_alarms_task',
        'schedule': 14400.0,  # Cada 4 horas
    },
    'update-inventory-metrics-daily': {
        'task': 'apps.inventory.tasks.update_all_inventory_metrics_task',
        'schedule': 86400.0,  # Cada día
    },
    'check-stock-alerts-every-6-hours': {
        'task': 'apps.inventory.tasks.check_stock_alerts_task',
        'schedule': 21600.0,  # Cada 6 horas
    },
    'execute-scheduled-reports-hourly': {
        'task': 'apps.reports.tasks.execute_scheduled_reports',
        'schedule': 3600.0,  # Cada hora
    },
    'cleanup-reports-weekly': {
        'task': 'apps.reports.tasks.cleanup_old_reports',
        'schedule': 604800.0,  # Cada semana
    },
}

app.conf.timezone = 'UTC'

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')