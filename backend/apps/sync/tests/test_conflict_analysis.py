from django.test import TestCase
from django.utils import timezone

from apps.sync.services import ConflictResolutionService


class DummyRecord:
    def __init__(self, **kwargs):
        for k, v in kwargs.items():
            setattr(self, k, v)


class ConflictAnalysisTests(TestCase):
    def test_duplicate_when_no_server_record(self):
        client_data = {'some': 'payload'}
        res = ConflictResolutionService._analyze_conflict(None, client_data)
        self.assertEqual(res['type'], 'DUPLICATE')
        self.assertEqual(res['priority'], 'LOW')

    def test_timestamp_diff_high_priority_when_off_by_more_than_an_hour(self):
        now = timezone.now()
        server = DummyRecord(created_at=now)
        client_time = (now - timezone.timedelta(hours=2)).isoformat()
        client_data = {'timestamp': client_time}
        res = ConflictResolutionService._analyze_conflict(server, client_data)
        self.assertEqual(res['type'], 'TIMESTAMP_DIFF')
        self.assertEqual(res['priority'], 'HIGH')

    def test_weight_outlier_high_priority_when_difference_big(self):
        # server average_weight 50.0, client 200.5 -> diff > 100
        server = DummyRecord(average_weight='50.0', created_at=timezone.now())
        client_data = {'type': 'weight', 'data': {'average_weight': '200.5'}}
        res = ConflictResolutionService._analyze_conflict(server, client_data)
        self.assertEqual(res['type'], 'DATA_MISMATCH')
        self.assertEqual(res['priority'], 'HIGH')
