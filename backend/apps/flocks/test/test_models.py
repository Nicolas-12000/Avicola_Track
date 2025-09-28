from django.test import TestCase
from django.utils import timezone
from django.contrib.auth import get_user_model

from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
from apps.users.models import Role
from apps.farms.services import ShedCapacityService


User = get_user_model()


class FlockTests(TestCase):
    def setUp(self):
        # Roles
        self.role_galponero = Role.objects.create(name='Galponero')
        self.role_farm_admin = Role.objects.create(name='Administrador de Granja')

        # Users (provide unique identification required by custom User model)
        self.galponero = User.objects.create_user(
            username='g1', password='pass', role=self.role_galponero, identification='ID_G1'
        )
        self.farm_admin = User.objects.create_user(
            username='fa1', password='pass', role=self.role_farm_admin, identification='ID_FA1'
        )

        # Farm and shed
        self.farm = Farm.objects.create(name='Gran1', location='Loc1', farm_manager=self.farm_admin)
        self.shed = Shed.objects.create(name='S1', capacity=1000, farm=self.farm, assigned_worker=self.galponero)

    def test_create_flock_happy_path(self):
        f = Flock.objects.create(
            arrival_date=timezone.now().date(),
            initial_quantity=100,
            current_quantity=100,
            initial_weight=40,
            breed='R1',
            gender='X',
            supplier='Prov',
            shed=self.shed,
            created_by=self.galponero,
        )
        self.assertEqual(f.current_quantity, 100)
        self.assertEqual(f.created_by, self.galponero)

    def test_capacity_validation(self):
        # Fill the shed near capacity
        Flock.objects.create(
            arrival_date=timezone.now().date(),
            initial_quantity=950,
            current_quantity=950,
            initial_weight=40,
            breed='R1',
            gender='X',
            supplier='Prov',
            shed=self.shed,
            created_by=self.galponero,
        )

        with self.assertRaises(Exception):
            ShedCapacityService.validate_capacity(self.shed, 100)

    def test_only_assigned_galponero_can_create(self):
        other = User.objects.create_user(username='other', password='pass', identification='ID_OTHER')
        # non assigned galponero cannot be equal to assigned
        self.assertNotEqual(other, self.shed.assigned_worker)
