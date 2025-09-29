from typing import Protocol, Any, Dict, Optional
import logging
from django.conf import settings
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


class NotificationAdapter(Protocol):
    def send(self, alarm: Any, recipient: Any, payload: Optional[Dict] = None) -> Dict:
        ...


class FCMAdapter:
    """Stubbed FCM adapter — performs no external calls unless credentials configured.
    In a production setup, use firebase_admin or pyfcm and configure credentials in settings.
    """

    def send(self, alarm, recipient, payload=None):
        logger.debug('FCMAdapter.send called for %s -> %s', alarm.id, recipient.id)
        # If settings.FCM_SERVER_KEY present, real sending could be implemented here.
        return {'status': 'skipped', 'reason': 'no-fcm-config'}


class EmailAdapter:
    def send(self, alarm, recipient, payload=None):
        try:
            subject = f'Alarma: {alarm.alarm_type} [{alarm.priority}]'
            body = alarm.description
            from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', None)
            if not from_email:
                return {'status': 'skipped', 'reason': 'no-from-email'}

            # recipient.email expected
            send_mail(subject, body, from_email, [recipient.email])
            return {'status': 'sent'}
        except Exception as e:
            logger.exception('Email send failed')
            return {'status': 'error', 'error': str(e)}


class LocalFallbackAdapter:
    """Fallback adapter that writes a NotificationLog record and returns status.
    This adapter is useful for testing and for environments without push/email set up.
    """

    def send(self, alarm, recipient, payload=None):
        try:
            from .models import NotificationLog
            nl = NotificationLog.objects.create(alarm=alarm, recipient=recipient, notification_type='PUSH', status='SENT')
            return {'status': 'sent', 'log_id': nl.id}
        except Exception as e:
            logger.exception('LocalFallbackAdapter failed')
            return {'status': 'error', 'error': str(e)}


def get_default_adapter():
    # decide adapter from settings; fallback to LocalFallbackAdapter
    adapter_name = getattr(settings, 'ALARMS_NOTIFICATION_ADAPTER', 'local')
    if adapter_name == 'fcm':
        return FCMAdapter()
    if adapter_name == 'email':
        return EmailAdapter()
    return LocalFallbackAdapter()
