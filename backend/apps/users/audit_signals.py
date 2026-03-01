from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.apps import apps
from .models import AuditLog
from .middleware import get_current_user

# Models to audit
MODELS_TO_AUDIT = [
    'farms.Farm',
    'veterinary.VeterinaryVisit',
    'veterinary.VaccinationRecord',
    'veterinary.Medication',
]


def _serialize_instance(instance):
    data = {}
    for field in instance._meta.fields:
        name = field.name
        try:
            val = getattr(instance, name)
            # For foreign keys, store pk or string repr
            if hasattr(val, 'pk'):
                data[name] = getattr(val, 'pk', str(val))
            else:
                data[name] = val
        except Exception:
            data[name] = None
    return data


def _should_audit(sender_label):
    return sender_label in MODELS_TO_AUDIT


@receiver(post_save)
def create_update_audit(sender, instance, created, **kwargs):
    sender_label = f"{sender._meta.app_label}.{sender.__name__}"
    if not _should_audit(sender_label):
        return
    # Try to resolve the actor from thread-local middleware if available
    try:
        actor = get_current_user()
    except Exception:
        actor = None

    action = 'created' if created else 'updated'
    snapshot = _serialize_instance(instance)

    # Compute a safe textual representation to avoid errors inside __str__
    try:
        object_repr = str(instance)
    except Exception:
        object_repr = f"{sender_label} (pk={getattr(instance, 'pk', None)})"

    try:
        AuditLog.objects.create(
            actor=actor,
            content_type=sender_label,
            object_id=str(getattr(instance, 'pk', None)),
            object_repr=object_repr,
            action=action,
            changes=snapshot,
        )
    except Exception:
        # Never let audit logging break the main request flow
        return


@receiver(post_delete)
def delete_audit(sender, instance, **kwargs):
    sender_label = f"{sender._meta.app_label}.{sender.__name__}"
    if not _should_audit(sender_label):
        return
    try:
        actor = get_current_user()
    except Exception:
        actor = None

    snapshot = _serialize_instance(instance)

    try:
        object_repr = str(instance)
    except Exception:
        object_repr = f"{sender_label} (pk={getattr(instance, 'pk', None)})"

    try:
        AuditLog.objects.create(
            actor=actor,
            content_type=sender_label,
            object_id=str(getattr(instance, 'pk', None)),
            object_repr=object_repr,
            action='deleted',
            changes=snapshot,
        )
    except Exception:
        return
