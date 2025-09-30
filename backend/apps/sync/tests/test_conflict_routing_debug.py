from django.urls import reverse
from rest_framework.test import APITestCase, APIClient
from django.utils import timezone

from django.contrib.auth import get_user_model
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
from apps.sync.models import SyncConflict

User = get_user_model()


class SyncConflictRoutingDebug(APITestCase):
    def setUp(self):
        self.manager = User.objects.create(username='mgrdebug', email='mgrdebug@example.com', identification='mgrdebug-01')
        self.reporter = User.objects.create(username='repdebug', email='repdebug@example.com', identification='repdebug-01')

        self.farm = Farm.objects.create(name='DebugFarm', location='Loc', farm_manager=self.manager)
        self.shed = Shed.objects.create(name='ShedDebug', capacity=100, farm=self.farm)
        self.flock = Flock.objects.create(arrival_date=timezone.now().date(), initial_quantity=10, current_quantity=10, initial_weight=1.0, breed='BR', gender='M', supplier='S', shed=self.shed, created_by=self.manager)

        self.client = APIClient()
        self.client.force_authenticate(user=self.manager)

    def test_client_routing_behaviour(self):
        conflict = SyncConflict.objects.create(conflict_type='DATA_MISMATCH', record_type='mortality', farm=self.farm, server_data={}, client_data={'flock_id': self.flock.id}, device_info={'d':'d'}, reported_by=self.reporter, priority='MEDIUM')

        list_url = reverse('sync-conflict-list')
        detail_url = reverse('sync-conflict-detail', kwargs={'pk': conflict.id})
        resolve_url = reverse('sync-conflict-resolve', kwargs={'pk': conflict.id})

        print('LIST URL:', list_url)
        print('DETAIL URL:', detail_url)
        print('RESOLVE URL:', resolve_url)

        # check allowed methods on list
        list_resp = self.client.options(list_url)
        print('LIST options status:', list_resp.status_code, 'Allow:', list_resp.get('Allow'))

        # check allowed methods on detail
        detail_resp = self.client.options(detail_url)
        print('DETAIL options status:', detail_resp.status_code, 'Allow:', detail_resp.get('Allow'))

        # try GET detail
        get_resp = self.client.get(detail_url)
        print('GET detail status:', get_resp.status_code)

        # try POST to resolve
        post_resp = self.client.post(resolve_url, {'resolution_type': 'client', 'resolution_data': {}}, format='json')
        print('POST resolve status:', post_resp.status_code)
        print('POST resolve data:', getattr(post_resp, 'data', None))

        self.assertIn(get_resp.status_code, (200, 404))
