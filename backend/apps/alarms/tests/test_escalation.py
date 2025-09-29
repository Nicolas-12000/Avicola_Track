import pytest
from django.utils import timezone
from datetime import timedelta

from django.contrib.auth import get_user_model

from apps.alarms.models import Alarm, AlarmConfiguration, AlarmEscalation
from apps.alarms.escalation import AlarmEscalationService
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
from apps.users.models import Role

User = get_user_model()


@pytest.mark.django_db
def test_escalate_pending_alarm_creates_escalation(monkeypatch):
    # setup admin user
    admin = User.objects.create(username='admin', email='a@example.com', is_superuser=True, identification='admin-1')

    user = User.objects.create(username='u', email='u@example.com', identification='u-1')
    farm = Farm.objects.create(name='Esc Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='S1', farm=farm, capacity=10)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=10, current_quantity=10, initial_weight=10, breed='X', gender='X', supplier='s', shed=shed)

    cfg = AlarmConfiguration.objects.create(alarm_type='MORTALITY', farm=farm, threshold_value=1.0, escalate_after_hours=1, escalate_to_admin=True, is_active=True)

    # create old alarm (created_at in the past)
    old_alarm = Alarm.objects.create(alarm_type='MORTALITY', description='old', priority='MEDIUM', farm=farm, flock=flock, configuration=cfg)
    # artificially set created_at older than threshold
    old_alarm.created_at = timezone.now() - timedelta(hours=2)
    old_alarm.save(update_fields=['created_at'])

    res = AlarmEscalationService.escalate_pending_alarms()
    assert res['escalated'] == 1
    assert Alarm.objects.get(id=old_alarm.id).status == 'ESCALATED'
    assert AlarmEscalation.objects.filter(alarm=old_alarm).exists()


@pytest.mark.django_db
def test_escalate_to_role_users(monkeypatch):
    # create role and user with that role
    role = Role.objects.create(name='Supervisor')
    role_user = User.objects.create(username='roleu', email='r@example.com', identification='r-1')
    role.user_set.add(role_user)

    user = User.objects.create(username='farmu', email='f@example.com', identification='f-1')
    farm = Farm.objects.create(name='Role Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='RS', farm=farm, capacity=10)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=10, current_quantity=10, initial_weight=10, breed='X', gender='X', supplier='s', shed=shed)

    cfg = AlarmConfiguration.objects.create(alarm_type='MORTALITY', farm=farm, threshold_value=1.0, escalate_after_hours=1, escalation_role_name='Supervisor', is_active=True)

    old_alarm = Alarm.objects.create(alarm_type='MORTALITY', description='old', priority='MEDIUM', farm=farm, flock=flock, configuration=cfg)
    old_alarm.created_at = timezone.now() - timedelta(hours=2)
    old_alarm.save(update_fields=['created_at'])

    res = AlarmEscalationService.escalate_pending_alarms()
    assert res['escalated'] == 1
    assert AlarmEscalation.objects.filter(alarm=old_alarm).exists()


@pytest.mark.django_db
def test_no_superuser_graceful(monkeypatch):
    # ensure no superusers exist
    User.objects.filter(is_superuser=True).delete()

    user = User.objects.create(username='u3', email='u3@example.com', identification='u3-1')
    farm = Farm.objects.create(name='NoAdmin Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='S3', farm=farm, capacity=5)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=5, current_quantity=5, initial_weight=5, breed='Y', gender='X', supplier='s', shed=shed)

    cfg = AlarmConfiguration.objects.create(alarm_type='MORTALITY', farm=farm, threshold_value=1.0, escalate_after_hours=1, escalate_to_admin=True, is_active=True)

    old_alarm = Alarm.objects.create(alarm_type='MORTALITY', description='old2', priority='MEDIUM', farm=farm, flock=flock, configuration=cfg)
    old_alarm.created_at = timezone.now() - timedelta(hours=2)
    old_alarm.save(update_fields=['created_at'])

    res = AlarmEscalationService.escalate_pending_alarms()
    # should escalate count but just not create escalation record (no target)
    assert res['escalated'] == 1
    assert Alarm.objects.get(id=old_alarm.id).status == 'ESCALATED'
    assert not AlarmEscalation.objects.filter(alarm=old_alarm).exists()


@pytest.mark.django_db
def test_do_not_escalate_recent_alarm():
    user = User.objects.create(username='u2', email='u2@example.com', identification='u2-1')
    farm = Farm.objects.create(name='NoEsc Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='S2', farm=farm, capacity=5)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=5, current_quantity=5, initial_weight=5, breed='Y', gender='X', supplier='s', shed=shed)

    cfg = AlarmConfiguration.objects.create(alarm_type='MORTALITY', farm=farm, threshold_value=1.0, escalate_after_hours=48, escalate_to_admin=True, is_active=True)

    recent_alarm = Alarm.objects.create(alarm_type='MORTALITY', description='recent', priority='MEDIUM', farm=farm, flock=flock, configuration=cfg)

    res = AlarmEscalationService.escalate_pending_alarms()
    assert res['escalated'] == 0
    assert Alarm.objects.get(id=recent_alarm.id).status == 'PENDING'
