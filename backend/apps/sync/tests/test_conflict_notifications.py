from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone

from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
from apps.alarms.models import NotificationLog
from apps.sync.models import SyncConflict
from apps.sync.services import ConflictResolutionService

User = get_user_model()


class ConflictNotificationTests(TestCase):
    def setUp(self):
        # farm manager
        self.manager = User.objects.create(username='mgr', email='mgr@example.com', identification='mgr-001')
        # reporter (the one who reported the conflict)
        self.reporter = User.objects.create(username='reporter', email='rep@example.com', identification='rep-001')
        self.farm = Farm.objects.create(name='NotifFarm', location='Place', farm_manager=self.manager)
        self.shed = Shed.objects.create(name='ShedN', capacity=500, farm=self.farm)
        self.flock = Flock.objects.create(
            arrival_date=timezone.now().date(),
            initial_quantity=50,
            current_quantity=50,
            initial_weight=1.0,
            breed='BR',
            gender='F',
            supplier='S',
            shed=self.shed,
            created_by=self.manager,
        )

    def test_notifications_sent_on_resolution(self):
        client_data = {'flock_id': self.flock.id, 'date': timezone.now().date().isoformat(), 'deaths': 2}
        conflict = SyncConflict.objects.create(
            conflict_type='DATA_MISMATCH',
            record_type='mortality',
            farm=self.farm,
            server_data={'id': None, 'data': {}},
            client_data=client_data,
            device_info={'device_id': 'd1'},
            reported_by=self.reporter,
            priority='MEDIUM',
        )

        # Resolve as client (this should trigger notifications to reporter and farm manager)
        ConflictResolutionService.resolve_conflict(conflict, resolution_type='client', resolution_data={}, resolved_by=self.manager)

        # Check mortality applied
        self.flock.refresh_from_db()
        self.assertEqual(self.flock.current_quantity, 48)

        # Ensure NotificationLog entries were created for the farm manager (LocalFallbackAdapter writes logs)
        # Expect logs for both manager and reporter
        manager_logs = NotificationLog.objects.filter(recipient=self.manager)
        reporter_logs = NotificationLog.objects.filter(recipient=self.reporter)

        self.assertTrue(manager_logs.exists(), 'Expected NotificationLog entries for farm manager')
        self.assertTrue(reporter_logs.exists(), 'Expected NotificationLog entries for reporter')

        # Spot-check fields
        nl_m = manager_logs.first()
        nl_r = reporter_logs.first()
        self.assertEqual(nl_m.recipient, self.manager)
        self.assertEqual(nl_r.recipient, self.reporter)
        self.assertIn('Conflicto', nl_m.alarm.description)
        self.assertIn('Conflicto', nl_r.alarm.description)
