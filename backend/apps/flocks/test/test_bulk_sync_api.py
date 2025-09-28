import json
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from django.utils import timezone
from apps.users.models import User
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock, DailyWeightRecord


class BulkSyncAPITest(APITestCase):
    def setUp(self):
        self.client = APIClient()
        # Create a test user and auth (include username required by AbstractUser)
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='pass1234', identification='U1')
        self.client.force_authenticate(self.user)

        # Create a farm manager user required by Farm.farm_manager
        self.manager = User.objects.create_user(username='mgr', email='mgr@example.com', password='mgrpass', identification='M1')

        # Create farm, shed, flock
        self.farm = Farm.objects.create(name='Finca Test', location='Ubicacion', farm_manager=self.manager)
        self.shed = Shed.objects.create(name='Galpon 1', farm=self.farm, capacity=1000)
        self.flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=100, current_quantity=100, initial_weight=1.2, breed='Ross', gender='X', supplier='Proveedor', shed=self.shed)

    def test_bulk_sync_creates_records_happy_path(self):
        payload = {
            'weight_records': [
                {
                    'flock_id': self.flock.id,
                    'date': timezone.now().date().isoformat(),
                    'average_weight': '45.5',
                    'sample_size': 12,
                    'client_id': 'c1'
                }
            ]
        }

        resp = self.client.post('/api/daily-weights/bulk-sync/', payload, format='json')
        assert resp.status_code == 200
        data = resp.json()
        assert data['total'] == 1
        assert data['successful'] == 1
        assert data['conflicts'] == 0
        # Check DB record created
        self.assertTrue(DailyWeightRecord.objects.filter(flock=self.flock, date=timezone.now().date()).exists())

    def test_bulk_sync_averages_duplicate_dates(self):
        # Create existing record
        today = timezone.now().date()
        DailyWeightRecord.objects.create(flock=self.flock, date=today, average_weight='40.0', sample_size=10, recorded_by=self.user)

        payload = {
            'weight_records': [
                {
                    'flock_id': self.flock.id,
                    'date': today.isoformat(),
                    'average_weight': '50.0',
                    'client_id': 'c2'
                }
            ]
        }

        resp = self.client.post('/api/daily-weights/bulk-sync/', payload, format='json')
        assert resp.status_code == 200
        data = resp.json()
        assert data['successful'] == 1
        # After averaging, new weight should be 45.0
        record = DailyWeightRecord.objects.get(flock=self.flock, date=today)
        self.assertAlmostEqual(float(record.average_weight), 45.0, places=2)

    def test_bulk_sync_reports_conflict(self):
        # Create existing record with very different weight
        today = timezone.now().date()
        DailyWeightRecord.objects.create(flock=self.flock, date=today, average_weight='10.0', sample_size=10, recorded_by=self.user)

        payload = {
            'weight_records': [
                {
                    'flock_id': self.flock.id,
                    'date': today.isoformat(),
                    'average_weight': '100.0',
                    'client_id': 'c3'
                }
            ]
        }

        resp = self.client.post('/api/daily-weights/bulk-sync/', payload, format='json')
        assert resp.status_code == 200
        data = resp.json()
        assert data['conflicts'] == 1
        assert data['details'][0]['status'] == 'conflicts'
