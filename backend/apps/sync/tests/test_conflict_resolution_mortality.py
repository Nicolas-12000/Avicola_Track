from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock, MortalityRecord, MortalityCause
from apps.sync.models import SyncConflict
from apps.sync.services import ConflictResolutionService

User = get_user_model()


class MortalityConflictResolutionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='tester')
        self.farm = Farm.objects.create(name='TestFarm', location='Here', farm_manager=self.user)
        self.shed = Shed.objects.create(name='Shed1', capacity=1000, farm=self.farm)
        self.flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=100, current_quantity=100, initial_weight=1.0, breed='BR', gender='M', supplier='S', shed=self.shed, created_by=self.user)

    def test_apply_client_mortality_success(self):
        client_data = {'flock_id': self.flock.id, 'date': timezone.now().date().isoformat(), 'deaths': 5, 'cause_name': 'Heat'}
        conflict = SyncConflict.objects.create(conflict_type='DATA_MISMATCH', record_type='mortality', farm=self.farm, server_data={'id': None, 'data': {}}, client_data=client_data, device_info={'device_id': 'dev1'}, reported_by=self.user, priority='MEDIUM')

        result = ConflictResolutionService.resolve_conflict(conflict, resolution_type='client', resolution_data={}, resolved_by=self.user)

        # Refresh from DB
        self.flock.refresh_from_db()
        self.assertEqual(result['action'], 'applied_client')
        # Mortality record created
        mr = MortalityRecord.objects.filter(flock=self.flock, date=timezone.now().date()).first()
        self.assertIsNotNone(mr)
        self.assertEqual(mr.deaths, 5)
        # Flock decreased
        self.assertEqual(self.flock.current_quantity, 95)
        # Conflict updated
        conflict.refresh_from_db()
        self.assertTrue(conflict.resolution_status.startswith('RESOLVED_CLIENT'))

    def test_apply_client_mortality_failure_exceeds(self):
        client_data = {'flock_id': self.flock.id, 'date': timezone.now().date().isoformat(), 'deaths': 200, 'cause_name': 'Disease'}
        conflict = SyncConflict.objects.create(conflict_type='DATA_MISMATCH', record_type='mortality', farm=self.farm, server_data={'id': None, 'data': {}}, client_data=client_data, device_info={'device_id': 'dev1'}, reported_by=self.user, priority='HIGH')

        with self.assertRaises(Exception):
            ConflictResolutionService.resolve_conflict(conflict, resolution_type='client', resolution_data={}, resolved_by=self.user)

        # Ensure no mortality record and flock unchanged
        self.flock.refresh_from_db()
        self.assertEqual(self.flock.current_quantity, 100)
        self.assertFalse(MortalityRecord.objects.filter(flock=self.flock).exists())