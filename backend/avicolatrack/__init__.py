# Esto garantizará que la aplicación sea siempre importada cuando Django se inicie.
# para que el shared_task use esta aplicación:
from .celery import app as celery_app

__all__ = ('celery_app',)