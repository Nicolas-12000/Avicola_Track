import io
import tempfile
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient

from apps.flocks.services import BreedReferenceService
from apps.flocks.models import BreedReference, ReferenceImportLog
from apps.inventory.models import InventoryItem, InventoryConsumptionRecord
from apps.farms.models import Farm, Shed


User = get_user_model()


class BreedReferenceImportTests(TestCase):
    def setUp(self):
        self.user = User.objects.create(username='importer')

    def test_import_excel_creates_references(self):
        # Create a simple xlsx in-memory
        from openpyxl import Workbook
        wb = Workbook()
        ws = wb.active
        ws.append(['breed', 'age_days', 'expected_weight', 'expected_consumption', 'tolerance_range'])
        ws.append(['Ross', 7, 150.0, 20.0, 10.0])

        tmp = tempfile.NamedTemporaryFile(suffix='.xlsx', delete=False)
        wb.save(tmp.name)
        tmp.close()

        log = BreedReferenceService.import_from_excel(tmp.name, self.user)

        self.assertEqual(log.successful_imports, 1)
        self.assertEqual(BreedReference.objects.count(), 1)


class InventoryMetricsTests(TestCase):
    def setUp(self):
        # create a farm manager user for the Farm model
        self.user = User.objects.create(username='admin')
        # create farm and shed with required non-null fields
        self.farm = Farm.objects.create(name='Finca Test', location='', farm_manager=self.user)
        self.shed = Shed.objects.create(name='Galpon A', farm=self.farm, capacity=100)

        self.item = InventoryItem.objects.create(
            name='Alimento A', description='', current_stock=1000, unit='KG', minimum_stock=100,
            farm=self.farm, shed=self.shed
        )

    def test_consumption_metrics_and_projection(self):
        # add consumption records for 30 days total 300 => daily avg 10
        from datetime import timedelta, date
        end = date.today()
        for i in range(30):
            d = end - timedelta(days=i)
            InventoryConsumptionRecord.objects.create(inventory_item=self.item, date=d, quantity_consumed=10)

        # Force update metrics
        self.item.update_consumption_metrics()

        self.assertAlmostEqual(float(self.item.daily_avg_consumption), 10.0, places=2)
        projected = self.item.projected_stockout_date
        self.assertIsNotNone(projected)
