import pytest
from django.utils import timezone

from apps.alarms.notifications import LocalFallbackAdapter
from apps.alarms.models import Alarm, NotificationLog, AlarmConfiguration
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
from apps.users.models import User


@pytest.mark.django_db
def test_local_fallback_writes_log():
    user = User.objects.create(username='notif', email='n@example.com', identification='n-1')
    farm = Farm.objects.create(name='NFarm', location='', farm_manager=user)
    shed = Shed.objects.create(name='NS', farm=farm, capacity=5)
    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=5, current_quantity=5, initial_weight=5, breed='B', gender='X', supplier='s', shed=shed)

    cfg = AlarmConfiguration.objects.create(alarm_type='MORTALITY', farm=farm, threshold_value=1.0, is_active=True)

    alarm = Alarm.objects.create(alarm_type='MORTALITY', description='d', priority='MEDIUM', farm=farm, flock=flock, configuration=cfg)

    adapter = LocalFallbackAdapter()
    res = adapter.send(alarm, user)

    assert res['status'] == 'sent'
    assert NotificationLog.objects.filter(alarm=alarm, recipient=user).exists()
