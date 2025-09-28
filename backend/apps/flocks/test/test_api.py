from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase, APIClient

from django.contrib.auth import get_user_model
from apps.users.models import Role
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock


User = get_user_model()


class FlockAPITests(APITestCase):
    def setUp(self):
        self.role_galponero = Role.objects.create(name='Galponero')
        self.role_farm_admin = Role.objects.create(name='Administrador de Granja')

        self.galponero = User.objects.create_user(
            username='g1', password='pass', role=self.role_galponero, identification='API_ID_G1'
        )
        self.farm_admin = User.objects.create_user(
            username='fa1', password='pass', role=self.role_farm_admin, identification='API_ID_FA1'
        )

        self.farm = Farm.objects.create(name='GranAPI', location='LocAPI', farm_manager=self.farm_admin)
        self.shed = Shed.objects.create(name='SAPI', capacity=500, farm=self.farm, assigned_worker=self.galponero)

        self.client = APIClient()

    def test_assigned_galponero_can_create_flock_and_created_by_set(self):
        self.client.force_authenticate(user=self.galponero)
        url = reverse('flock-list')
        data = {
            'arrival_date': timezone.now().date(),
            'initial_quantity': 50,
            'initial_weight': 45,
            'breed': 'RAPI',
            'gender': 'X',
            'supplier': 'ProvAPI',
            'shed': self.shed.id,
        }
        resp = self.client.post(url, data, format='json')
        self.assertEqual(resp.status_code, 201)
        flock_id = resp.data.get('id')
        f = Flock.objects.get(id=flock_id)
        self.assertEqual(f.created_by, self.galponero)

    def test_unassigned_user_cannot_create_flock(self):
        other = User.objects.create_user(username='other', password='pass', identification='API_ID_OTHER')
        self.client.force_authenticate(user=other)
        url = reverse('flock-list')
        data = {
            'arrival_date': timezone.now().date(),
            'initial_quantity': 10,
            'initial_weight': 40,
            'breed': 'RAPI',
            'gender': 'X',
            'supplier': 'ProvAPI',
            'shed': self.shed.id,
        }
        resp = self.client.post(url, data, format='json')
        self.assertIn(resp.status_code, (400, 403))
