from celery import shared_task
from .services import AlarmEvaluationEngine


@shared_task
def evaluate_all_alarms_task():
    return AlarmEvaluationEngine.evaluate_all_farms()


@shared_task
def escalate_unresolved_alarms_task():
    from .services import AlarmEscalationService

    return AlarmEscalationService.escalate_pending_alarms()
