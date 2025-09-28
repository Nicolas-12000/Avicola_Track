from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APITestCase, APIClient

from apps.users.models import Role, User
from apps.farms.models import Farm, Shed
from django.core.cache import cache


class ShedDashboardAPITests(APITestCase):
    def setUp(self):
        self.client = APIClient()

        # Roles
        self.role_admin_system = Role.objects.create(name='Administrador Sistema')
        self.role_farm_admin = Role.objects.create(name='Administrador de Granja')
        self.role_galponero = Role.objects.create(name='Galponero')

        # Users
        self.admin = User.objects.create_user(username='sysadmin', email='sys@x', password='p', identification='S1', role=self.role_admin_system)
        self.farm_admin = User.objects.create_user(username='farmadm', email='fa@x', password='p', identification='F1', role=self.role_farm_admin)
        self.galponero = User.objects.create_user(username='galp', email='g@x', password='p', identification='G1', role=self.role_galponero)

        # Create farms and sheds
        self.farm1 = Farm.objects.create(name='Farm1', location='L1', farm_manager=self.farm_admin)
        self.farm2 = Farm.objects.create(name='Farm2', location='L2', farm_manager=self.admin)

        self.shed1 = Shed.objects.create(name='ShedA', capacity=100, farm=self.farm1, assigned_worker=self.galponero)
        self.shed2 = Shed.objects.create(name='ShedB', capacity=200, farm=self.farm2)

    def test_admin_sees_all_sheds(self):
        self.client.force_authenticate(self.admin)
        url = reverse('shed-dashboard')
        cache.clear()
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        # Admin should see both sheds
        self.assertIn('sheds', data)
        self.assertGreaterEqual(len(data['sheds']), 2)

    def test_farm_admin_sees_own_farm_sheds(self):
        self.client.force_authenticate(self.farm_admin)
        url = reverse('shed-dashboard')
        cache.clear()
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        # Farm admin should see sheds for farm1 only
        shed_ids = [s['id'] for s in data.get('sheds', [])]
        self.assertIn(self.shed1.id, shed_ids)
        self.assertNotIn(self.shed2.id, shed_ids)

    def test_galponero_sees_assigned_shed_only(self):
        self.client.force_authenticate(self.galponero)
        url = reverse('shed-dashboard')
        cache.clear()
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        shed_ids = [s['id'] for s in data.get('sheds', [])]
        self.assertEqual(shed_ids, [self.shed1.id])

    def test_cache_keeps_last_updated_same_between_calls(self):
        self.client.force_authenticate(self.admin)
        url = reverse('shed-dashboard')
        cache.clear()
        r1 = self.client.get(url)
        self.assertEqual(r1.status_code, 200)
        data1 = r1.json()
        # Call again immediately
        r2 = self.client.get(url)
        data2 = r2.json()
        # Because of cache_page(120) the last_updated should be identical
        self.assertEqual(data1.get('last_updated'), data2.get('last_updated'))
