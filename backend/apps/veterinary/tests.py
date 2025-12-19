from django.test import TestCase
from django.contrib.auth import get_user_model
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
from .models import (
    VeterinaryVisit,
    VaccinationRecord,
    Medication,
    Disease,
    BiosecurityChecklist
)

User = get_user_model()


class VeterinaryModelsTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='vet', password='test123')
        self.farm = Farm.objects.create(name='Test Farm', location='Test')
        self.shed = Shed.objects.create(farm=self.farm, name='Shed 1', capacity=1000)
        self.flock = Flock.objects.create(
            shed=self.shed,
            breed='Broiler',
            initial_quantity=500,
            current_quantity=500,
            arrival_date='2025-01-01',
            status='active'
        )
    
    def test_veterinary_visit_creation(self):
        visit = VeterinaryVisit.objects.create(
            flock=self.flock,
            veterinarian=self.user,
            visit_date='2025-01-15',
            visit_type='routine',
            status='scheduled'
        )
        self.assertEqual(visit.status, 'scheduled')
        self.assertIsNotNone(visit.id)
    
    def test_vaccination_record_creation(self):
        vaccination = VaccinationRecord.objects.create(
            flock=self.flock,
            vaccine_name='Newcastle',
            vaccine_type='viral',
            scheduled_date='2025-01-20',
            administration_route='oral',
            status='scheduled'
        )
        self.assertEqual(vaccination.vaccine_name, 'Newcastle')
    
    def test_medication_creation(self):
        medication = Medication.objects.create(
            flock=self.flock,
            medication_name='Amoxicillin',
            medication_type='antibiotic',
            start_date='2025-01-10',
            duration_days=5,
            dosage=100.0,
            dosage_unit='mg',
            administration_route='water',
            frequency='twice_daily',
            status='active'
        )
        self.assertEqual(medication.status, 'active')
    
    def test_disease_creation(self):
        disease = Disease.objects.create(
            name='Newcastle Disease',
            scientific_name='Avian paramyxovirus',
            category='viral',
            severity='high',
            transmission_mode='airborne',
            is_notifiable=True
        )
        self.assertTrue(disease.is_notifiable)
    
    def test_biosecurity_checklist_creation(self):
        checklist = BiosecurityChecklist.objects.create(
            farm=self.farm,
            shed=self.shed,
            checklist_type='daily',
            performed_date='2025-01-15',
            performed_by=self.user,
            status='completed',
            compliance_score=95.5
        )
        self.assertEqual(checklist.compliance_score, 95.5)
