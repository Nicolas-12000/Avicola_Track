import pytest
from django.utils import timezone

from django.contrib.auth import get_user_model

from apps.alarms.services import AlarmEvaluationEngine
from apps.alarms.models import Alarm, AlarmConfiguration
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock, MortalityRecord


User = get_user_model()


@pytest.mark.django_db
def test_mortality_threshold_creates_alarm_and_notifies(monkeypatch):
    # create a farm manager user and assign (Farm.farm_manager is required)
    user = User.objects.create(username='fm', email='fm@example.com')
    # Setup farm, shed, flock
    farm = Farm.objects.create(name='Test Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='Shed A', farm=farm, capacity=100)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=100, current_quantity=100, initial_weight=100, breed='Test', gender='X', supplier='Sup', shed=shed)

    # config: low threshold so a small mortality triggers
    config = AlarmConfiguration.objects.create(
        alarm_type='MORTALITY',
        farm=farm,
        threshold_value=1.0,
        critical_threshold=5.0,
        evaluation_period_hours=24,
        is_active=True,
        notify_farm_manager=True,
    )

    # monkeypatch notification sending to capture call
    called = {'count': 0}

    def fake_send(alarm, cfg):
        called['count'] += 1

    monkeypatch.setattr('apps.alarms.services.AlarmNotificationService.send_alarm_notifications', fake_send)

    # create a mortality record that exceeds threshold
    today = timezone.now().date()
    # deaths such that rate > 1%: 2 deaths on 102 original ~1.96%
    MortalityRecord.objects.create(flock=flock, date=today, deaths=2, recorded_by=user)

    created = AlarmEvaluationEngine._evaluate_mortality_alarms(farm, config)

    assert created == 1
    alarm = Alarm.objects.filter(alarm_type='MORTALITY', flock=flock).first()
    assert alarm is not None
    assert called['count'] == 1


@pytest.mark.django_db
def test_duplicate_unresolved_alarm_prevents_second_creation(monkeypatch):
    user = User.objects.create(username='u2', email='u2@example.com')
    farm = Farm.objects.create(name='Dup Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='Shed B', farm=farm, capacity=50)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=50, current_quantity=50, initial_weight=50, breed='B', gender='X', supplier='S', shed=shed)

    config = AlarmConfiguration.objects.create(
        alarm_type='MORTALITY',
        farm=farm,
        threshold_value=1.0,
        evaluation_period_hours=24,
        is_active=True,
        notify_farm_manager=False,
    )

    today = timezone.now().date()
    MortalityRecord.objects.create(flock=flock, date=today, deaths=1, recorded_by=user)

    # create an existing unresolved alarm for this flock/date using structured source fields
    existing_rec = MortalityRecord.objects.filter(flock=flock, date=today).first()
    # attach alarm to the same mortality record
    Alarm.objects.create(alarm_type='MORTALITY', description=f'Existing alarm for {today}', priority='MEDIUM', flock=flock, farm=farm, source_type='mortality', source_date=today, source_id=existing_rec.id)

    monkeypatch.setattr('apps.alarms.services.AlarmNotificationService.send_alarm_notifications', lambda a, c: None)

    created = AlarmEvaluationEngine._evaluate_mortality_alarms(farm, config)
    assert created == 0


@pytest.mark.django_db
def test_priority_high_when_exceeds_critical(monkeypatch):
    user = User.objects.create(username='u3', email='u3@example.com')
    farm = Farm.objects.create(name='Crit Farm', location='', farm_manager=user)
    shed = Shed.objects.create(name='Shed C', farm=farm, capacity=20)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=20, current_quantity=20, initial_weight=20, breed='C', gender='X', supplier='S', shed=shed)

    config = AlarmConfiguration.objects.create(
        alarm_type='MORTALITY',
        farm=farm,
        threshold_value=2.0,
        critical_threshold=3.0,
        evaluation_period_hours=24,
        is_active=True,
    )

    # create mortality record that exceeds critical (e.g., 1 death on 21 original ~4.76%)
    today = timezone.now().date()
    MortalityRecord.objects.create(flock=flock, date=today, deaths=1, recorded_by=user)

    monkeypatch.setattr('apps.alarms.services.AlarmNotificationService.send_alarm_notifications', lambda a, c: None)

    created = AlarmEvaluationEngine._evaluate_mortality_alarms(farm, config)
    assert created == 1
    alarm = Alarm.objects.filter(alarm_type='MORTALITY', flock=flock).first()
    assert alarm is not None
    assert alarm.priority == 'HIGH'
