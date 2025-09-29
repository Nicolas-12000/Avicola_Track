import logging
from django.utils import timezone
from datetime import timedelta

from .models import Alarm, AlarmEscalation

logger = logging.getLogger(__name__)


class AlarmEscalationService:
    @staticmethod
    def escalate_pending_alarms():
        """Find pending alarms with a configuration that specifies escalate_after_hours
        and escalate them if they are older than that window.

        Returns a dict with counts.
        """
        now = timezone.now()
        escalated = 0
        errors = 0

        pending = Alarm.objects.filter(status='PENDING', configuration__isnull=False, configuration__escalate_after_hours__isnull=False)

        for alarm in pending.select_related('configuration'):
            try:
                cfg = alarm.configuration
                threshold = cfg.escalate_after_hours
                if not threshold:
                    continue

                age = now - alarm.created_at
                if age >= timedelta(hours=threshold):
                    # escalate
                    target_user = None
                    # prefer explicit role-based escalation
                    role_name = getattr(cfg, 'escalation_role_name', None)
                    if role_name:
                        # find users with the role
                        from apps.users.models import Role
                        users = []
                        try:
                            role = Role.objects.filter(name=role_name).first()
                            if role:
                                users = role.user_set.all()
                        except Exception:
                            users = []

                        target_user = users.first() if users else None

                    # fallback to escalate to admin if configured
                    if not target_user and cfg.escalate_to_admin:
                        from django.contrib.auth import get_user_model
                        User = get_user_model()
                        admin = User.objects.filter(is_superuser=True).first()
                        target_user = admin

                    # mark as escalated and create record
                    alarm.status = 'ESCALATED'
                    alarm.save(update_fields=['status'])

                    if target_user:
                        AlarmEscalation.objects.create(alarm=alarm, escalated_to=target_user, escalation_reason='escalation_by_policy')

                    # Send notification (best-effort)
                    try:
                        from .services import AlarmNotificationService
                        if target_user:
                            AlarmNotificationService._send_notification_to_user(alarm, target_user)
                    except Exception:
                        logger.exception('Failed to notify escalation target')

                    escalated += 1
            except Exception:
                errors += 1
                logger.exception('Failed to process escalation for alarm %s', getattr(alarm, 'id', None))

        return {'escalated': escalated, 'errors': errors}
