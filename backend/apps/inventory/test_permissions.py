from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient

from apps.farms.models import Farm, Shed
from apps.inventory.models import InventoryItem

User = get_user_model()


class InventoryPermissionTests(TestCase):
    def setUp(self):
        # create users with different roles via simple attributes used in permission checks
        self.admin = User.objects.create(username='admin', identification='admin-1', is_staff=True)
        self.farm_manager = User.objects.create(username='farmmgr', identification='farmmgr-1')
        self.galponero = User.objects.create(username='galponero', identification='galponero-1')

        self.farm = Farm.objects.create(name='Finca P', location='', farm_manager=self.farm_manager)
        self.shed = Shed.objects.create(name='Galpon P', farm=self.farm, capacity=50, assigned_worker=self.galponero)

        self.item = InventoryItem.objects.create(
            name='Alimento B', description='', current_stock=200, unit='KG', minimum_stock=20,
            farm=self.farm, shed=self.shed
        )

        self.client = APIClient()

    def test_admin_can_bulk_update(self):
        self.client.force_authenticate(self.admin)
        payload = {'stock_updates': [{'inventory_id': self.item.id, 'new_stock': self.item.current_stock - 10, 'client_id': 'c1'}]}
        resp = self.client.post('/api/inventory/bulk-update-stock/', payload, format='json')
        self.assertIn(resp.status_code, (200, 202))

    def test_galponero_can_update_own_shed(self):
        self.client.force_authenticate(self.galponero)
        payload = {'stock_updates': [{'inventory_id': self.item.id, 'new_stock': self.item.current_stock - 5, 'client_id': 'c2'}]}
        resp = self.client.post('/api/inventory/bulk-update-stock/', payload, format='json')
        self.assertIn(resp.status_code, (200, 202))

    def test_other_user_cannot_update(self):
        other = User.objects.create(username='other', identification='other-1')
        self.client.force_authenticate(other)
        payload = {'stock_updates': [{'inventory_id': self.item.id, 'new_stock': self.item.current_stock - 1, 'client_id': 'c3'}]}
        resp = self.client.post('/api/inventory/bulk-update-stock/', payload, format='json')
        # Endpoint currently returns 200 and includes per-item error details when permission denied.
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertIn('results', body)
        self.assertTrue(any(r.get('status') == 'error' for r in body['results']))
