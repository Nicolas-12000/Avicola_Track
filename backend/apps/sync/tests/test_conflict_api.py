from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from django.utils import timezone

from django.contrib.auth import get_user_model
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock, MortalityRecord
from apps.alarms.models import NotificationLog
from apps.sync.models import SyncConflict

User = get_user_model()


class SyncConflictAPITests(APITestCase):
    def setUp(self):
        # create manager and reporter
        self.manager = User.objects.create(username='mgrapi', email='mgrapi@example.com', identification='mgrapi-01')
        self.reporter = User.objects.create(username='repapi', email='repapi@example.com', identification='repapi-01')

        self.farm = Farm.objects.create(name='APIFarm', location='Loc', farm_manager=self.manager)
        self.shed = Shed.objects.create(name='ShedAPI', capacity=300, farm=self.farm)
        self.flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=30, current_quantity=30, initial_weight=1.0, breed='BR', gender='M', supplier='S', shed=self.shed, created_by=self.manager)

        # authenticate client as manager
        self.client = APIClient()
        self.client.force_authenticate(user=self.manager)

    def test_resolve_conflict_endpoint_applies_mortality_and_notifies(self):
        client_data = {'flock_id': self.flock.id, 'date': timezone.now().date().isoformat(), 'deaths': 3}
        conflict = SyncConflict.objects.create(conflict_type='DATA_MISMATCH', record_type='mortality', farm=self.farm, server_data={'id': None, 'data': {}}, client_data=client_data, device_info={'device_id': 'dapi'}, reported_by=self.reporter, priority='MEDIUM')

        # Use APIClient to POST to the resolve action (end-to-end routing)
        url = reverse('sync-conflict-resolve', kwargs={'pk': conflict.id})
        resp = self.client.post(url, {'resolution_type': 'client', 'resolution_data': {}}, format='json')
        self.assertEqual(resp.status_code, 200)

        # refresh and check mortality applied
        self.flock.refresh_from_db()
        mr = MortalityRecord.objects.filter(flock=self.flock, date=timezone.now().date()).first()
        self.assertIsNotNone(mr)
        self.assertEqual(mr.deaths, 3)
        self.assertEqual(self.flock.current_quantity, 27)

        # check notification logs for both manager and reporter
        ml = NotificationLog.objects.filter(recipient=self.manager)
        rl = NotificationLog.objects.filter(recipient=self.reporter)
        self.assertTrue(ml.exists())
        self.assertTrue(rl.exists())