import pytest
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.flocks.models import Flock
from apps.users.models import Role
from apps.flocks.services import MortalityService


User = get_user_model()


@pytest.mark.django_db
def test_register_mortality_reduces_flock_quantity(client, django_user_model):
    user = django_user_model.objects.create(username='u1', identification='id-u1')
    # Create minimal farm/shed via factories or direct creation
    from apps.farms.models import Farm, Shed
    # Create a farm manager user
    from apps.users.models import Role
    role_mgr, _ = Role.objects.get_or_create(name='Administrador de Granja')
    farm_manager = django_user_model.objects.create(username='fm', identification='id-fm', role=role_mgr)
    farm = Farm.objects.create(name='F1', location='', farm_manager=farm_manager)
    shed = Shed.objects.create(name='S1', farm=farm, capacity=100)

    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=50, current_quantity=50, initial_weight=40, breed='R', gender='M', supplier='S', shed=shed)

    payload = [{
        'flock_id': flock.id,
        'date': timezone.now().date().isoformat(),
        'deaths': 5,
        'client_id': 'c1'
    }]

    results = MortalityService.register_mortality_batch(payload, user)

    assert len(results) == 1
    assert results[0]['status'] == 'success'

    flock.refresh_from_db()
    assert flock.current_quantity == 45


@pytest.mark.django_db
def test_register_mortality_exceeds_quantity_raises(django_user_model):
    user = django_user_model.objects.create(username='u2', identification='id-u2')
    from apps.farms.models import Farm, Shed
    role_mgr2, _ = Role.objects.get_or_create(name='Administrador de Granja')
    farm_manager = django_user_model.objects.create(username='fm2', identification='id-fm2', role=role_mgr2)
    farm = Farm.objects.create(name='F2', location='', farm_manager=farm_manager)
    shed = Shed.objects.create(name='S2', farm=farm, capacity=100)

    flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=10, current_quantity=10, initial_weight=40, breed='R', gender='M', supplier='S', shed=shed)

    payload = [{
        'flock_id': flock.id,
        'date': timezone.now().date().isoformat(),
        'deaths': 20,
        'client_id': 'c2'
    }]

    results = MortalityService.register_mortality_batch(payload, user)

    assert len(results) == 1
    assert results[0]['status'] == 'error'
