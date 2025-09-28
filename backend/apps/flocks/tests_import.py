import io
import tempfile
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient

from openpyxl import Workbook

User = get_user_model()


class BreedReferenceEndpointImportTests(TestCase):
    def setUp(self):
        # make uploader staff so permission IsAssignedShedWorkerOrFarmAdmin allows access
        self.user = User.objects.create(username='uploader', identification='uploader-1', is_staff=True)
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def _make_xlsx(self, rows):
        wb = Workbook()
        ws = wb.active
        for r in rows:
            ws.append(r)

        tmp = tempfile.NamedTemporaryFile(suffix='.xlsx', delete=False)
        wb.save(tmp.name)
        tmp.close()
        return tmp.name

    def test_import_endpoint_happy_path(self):
        path = self._make_xlsx([
            ['breed', 'age_days', 'expected_weight', 'expected_consumption', 'tolerance_range'],
            ['Ross', 7, 150.0, 20.0, 10.0],
        ])

        with open(path, 'rb') as fh:
            resp = self.client.post('/api/references/import-excel/', {'file': fh}, format='multipart')

        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertIn('successful_imports', data)
        self.assertEqual(data['successful_imports'], 1)

    def test_import_endpoint_missing_file(self):
        resp = self.client.post('/api/references/import-excel/', {})
        self.assertEqual(resp.status_code, 400)
