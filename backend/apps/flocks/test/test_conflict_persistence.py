import json
from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from django.utils import timezone
from apps.users.models import User
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock, DailyWeightRecord, SyncConflict


class ConflictPersistenceAPITest(APITestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='pass1234', identification='U1')
        self.client.force_authenticate(self.user)

        # Create a farm manager user required by Farm.farm_manager
        self.manager = User.objects.create_user(username='mgr', email='mgr@example.com', password='mgrpass', identification='M1')

        # Create farm, shed, flock
        self.farm = Farm.objects.create(name='Finca Test', location='Ubicacion', farm_manager=self.manager)
        self.shed = Shed.objects.create(name='Galpon Conflict', farm=self.farm, capacity=1000)
        self.flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=100, current_quantity=100, initial_weight=1.2, breed='Ross', gender='X', supplier='Proveedor', shed=self.shed)

    def test_conflict_is_persisted_on_bulk_sync(self):
        # Create existing record with very different weight to force conflict
        today = timezone.now().date()
        DailyWeightRecord.objects.create(flock=self.flock, date=today, average_weight='10.0', sample_size=10, recorded_by=self.user)

        payload = {
            'weight_records': [
                {
                    'flock_id': self.flock.id,
                    'date': today.isoformat(),
                    'average_weight': '100.0',
                    'client_id': 'client-conflict-1'
                }
            ]
        }

        resp = self.client.post('/api/daily-weights/bulk-sync/', payload, format='json')
        assert resp.status_code == 200
        data = resp.json()
        assert data['conflicts'] == 1
        detail = data['details'][0]
        assert detail['status'] == 'conflicts'
        assert 'server_conflict_id' in detail

        conflict_id = detail['server_conflict_id']
        # Ensure SyncConflict exists and references the flock and source
        conflict = SyncConflict.objects.get(id=conflict_id)
        assert conflict.source == 'daily_weight'
        assert conflict.flock.id == self.flock.id
        # incoming_weight may be stored as '100.0' so compare numerically
        assert float(conflict.payload.get('incoming_weight')) == 100.0

    def test_resolve_conflict_marks_resolved(self):
        # Create a conflict directly
        conflict = SyncConflict.objects.create(
            source='daily_weight',
            client_id='c-res-1',
            payload={'flock_id': self.flock.id, 'date': timezone.now().date().isoformat(), 'incoming_weight': '99'},
            flock_id=self.flock.id
        )

        url = reverse('flock-conflict-resolve', kwargs={'pk': conflict.id})
        resp = self.client.post(url, {'resolution': 'manual', 'note': 'Reviewed and merged'}, format='json')
        assert resp.status_code == 200
        conflict.refresh_from_db()
        assert conflict.resolution == 'manual'
        assert conflict.resolved_at is not None
        assert conflict.resolved_by.id == self.user.id
