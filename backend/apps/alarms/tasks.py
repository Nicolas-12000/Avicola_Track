from celery import shared_task
from .services import AlarmEvaluationEngine


@shared_task
def evaluate_all_alarms_task():
    return AlarmEvaluationEngine.evaluate_all_farms()


@shared_task
def escalate_unresolved_alarms_task():
    from .services import AlarmEscalationService

    return AlarmEscalationService.escalate_pending_alarms()


@shared_task
def cleanup_old_notifications_task():
    """Hard-delete read notifications older than 30 days and soft-deleted ones."""
    from datetime import timedelta
    from django.utils import timezone
    from .models import NotificationLog

    expiry = timezone.now() - timedelta(days=30)
    old_read = NotificationLog.objects.filter(read_at__isnull=False, read_at__lt=expiry)
    soft_deleted = NotificationLog.objects.filter(is_deleted=True)
    deleted, _ = (old_read | soft_deleted).distinct().delete()
    return f'Deleted {deleted} old/soft-deleted notifications'
