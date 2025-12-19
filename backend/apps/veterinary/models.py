from django.db import models
from django.contrib.auth import get_user_model
from apps.flocks.models import Flock
from apps.farms.models import Farm, Shed

User = get_user_model()


class VeterinaryVisit(models.Model):
    VISIT_TYPES = [
        ('routine', 'Rutina'),
        ('emergency', 'Emergencia'),
        ('vaccination', 'Vacunación'),
        ('treatment', 'Tratamiento'),
    ]
    
    STATUS_CHOICES = [
        ('scheduled', 'Programada'),
        ('in_progress', 'En Progreso'),
        ('completed', 'Completada'),
        ('cancelled', 'Cancelada'),
    ]
    
    flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='veterinary_visits')
    veterinarian = models.ForeignKey(User, on_delete=models.CASCADE, related_name='veterinary_visits')
    visit_date = models.DateTimeField()
    visit_type = models.CharField(max_length=20, choices=VISIT_TYPES)
    diagnosis = models.TextField(null=True, blank=True)
    treatment = models.TextField(null=True, blank=True)
    prescribed_medications = models.TextField(null=True, blank=True)
    notes = models.TextField(null=True, blank=True)
    photo_urls = models.JSONField(default=list, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-visit_date']
        
    def __str__(self):
        return f"Visita {self.visit_type} - Lote {self.flock_id} - {self.visit_date.date()}"


class VaccinationRecord(models.Model):
    VACCINE_TYPES = [
        ('viral', 'Viral'),
        ('bacterial', 'Bacteriana'),
        ('parasitic', 'Parasitaria'),
    ]
    
    ADMINISTRATION_ROUTES = [
        ('oral', 'Oral'),
        ('injection', 'Inyección'),
        ('spray', 'Spray'),
        ('water', 'Agua'),
    ]
    
    STATUS_CHOICES = [
        ('scheduled', 'Programada'),
        ('applied', 'Aplicada'),
        ('missed', 'Perdida'),
        ('rescheduled', 'Reprogramada'),
    ]
    
    flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='vaccinations')
    vaccine_name = models.CharField(max_length=200)
    vaccine_type = models.CharField(max_length=20, choices=VACCINE_TYPES)
    scheduled_date = models.DateTimeField()
    applied_date = models.DateTimeField(null=True, blank=True)
    applied_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    administration_route = models.CharField(max_length=20, choices=ADMINISTRATION_ROUTES)
    dosage = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    dosage_unit = models.CharField(max_length=20, null=True, blank=True)
    bird_count = models.IntegerField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    notes = models.TextField(null=True, blank=True)
    batch_number = models.CharField(max_length=100, null=True, blank=True)
    expiration_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-scheduled_date']
        
    def __str__(self):
        return f"{self.vaccine_name} - Lote {self.flock_id} - {self.scheduled_date.date()}"


class Medication(models.Model):
    MEDICATION_TYPES = [
        ('antibiotic', 'Antibiótico'),
        ('antiparasitic', 'Antiparasitario'),
        ('vitamin', 'Vitamina'),
        ('probiotic', 'Probiótico'),
        ('vaccine', 'Vacuna'),
        ('other', 'Otro'),
    ]
    
    ADMINISTRATION_ROUTES = [
        ('water', 'Agua'),
        ('feed', 'Alimento'),
        ('injection', 'Inyección'),
        ('oral', 'Oral'),
    ]
    
    FREQUENCIES = [
        ('once_daily', 'Una vez al día'),
        ('twice_daily', 'Dos veces al día'),
        ('three_times_daily', 'Tres veces al día'),
        ('continuous', 'Continuo'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Activo'),
        ('completed', 'Completado'),
        ('discontinued', 'Descontinuado'),
    ]
    
    flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='medications')
    medication_name = models.CharField(max_length=200)
    medication_type = models.CharField(max_length=20, choices=MEDICATION_TYPES)
    active_ingredient = models.CharField(max_length=200, null=True, blank=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField(null=True, blank=True)
    duration_days = models.IntegerField()
    dosage = models.DecimalField(max_digits=10, decimal_places=2)
    dosage_unit = models.CharField(max_length=20)
    administration_route = models.CharField(max_length=20, choices=ADMINISTRATION_ROUTES)
    frequency = models.CharField(max_length=20, choices=FREQUENCIES)
    prescribed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    reason = models.TextField(null=True, blank=True)
    withdrawal_period_days = models.IntegerField(null=True, blank=True)
    withdrawal_end_date = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    notes = models.TextField(null=True, blank=True)
    application_dates = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-start_date']
        
    def __str__(self):
        return f"{self.medication_name} - Lote {self.flock_id}"


class Disease(models.Model):
    CATEGORIES = [
        ('viral', 'Viral'),
        ('bacterial', 'Bacteriana'),
        ('parasitic', 'Parasitaria'),
        ('fungal', 'Fúngica'),
        ('nutritional', 'Nutricional'),
        ('other', 'Otra'),
    ]
    
    SEVERITIES = [
        ('low', 'Baja'),
        ('medium', 'Media'),
        ('high', 'Alta'),
        ('critical', 'Crítica'),
    ]
    
    TRANSMISSION_MODES = [
        ('direct', 'Directa'),
        ('airborne', 'Aérea'),
        ('water', 'Agua'),
        ('vector', 'Vector'),
        ('vertical', 'Vertical'),
    ]
    
    name = models.CharField(max_length=200)
    scientific_name = models.CharField(max_length=200)
    category = models.CharField(max_length=20, choices=CATEGORIES)
    severity = models.CharField(max_length=20, choices=SEVERITIES)
    transmission_mode = models.CharField(max_length=20, choices=TRANSMISSION_MODES)
    symptoms = models.JSONField(default=list)
    affected_systems = models.JSONField(default=list)
    diagnosis = models.TextField(null=True, blank=True)
    treatments = models.JSONField(default=list)
    prevention_measures = models.JSONField(default=list)
    vaccine_available = models.CharField(max_length=200, null=True, blank=True)
    incubation_period_days = models.IntegerField(null=True, blank=True)
    mortality_rate = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    morbidity_rate = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    image_url = models.URLField(null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    is_notifiable = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['name']
        
    def __str__(self):
        return self.name


class BiosecurityChecklist(models.Model):
    CHECKLIST_TYPES = [
        ('daily', 'Diario'),
        ('weekly', 'Semanal'),
        ('monthly', 'Mensual'),
        ('pre_flock', 'Pre-Lote'),
        ('post_flock', 'Post-Lote'),
        ('emergency', 'Emergencia'),
    ]
    
    STATUS_CHOICES = [
        ('completed', 'Completado'),
        ('incomplete', 'Incompleto'),
        ('failed', 'Fallido'),
    ]
    
    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='biosecurity_checklists')
    shed = models.ForeignKey(Shed, on_delete=models.CASCADE, null=True, blank=True, related_name='biosecurity_checklists')
    checklist_type = models.CharField(max_length=20, choices=CHECKLIST_TYPES)
    performed_date = models.DateTimeField()
    performed_by = models.ForeignKey(User, on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    items = models.JSONField(default=list)
    compliance_score = models.DecimalField(max_digits=5, decimal_places=2)
    notes = models.TextField(null=True, blank=True)
    photo_urls = models.JSONField(default=list, blank=True)
    corrective_actions = models.TextField(null=True, blank=True)
    corrective_actions_deadline = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-performed_date']
        
    def __str__(self):
        return f"Checklist {self.checklist_type} - Granja {self.farm_id} - {self.performed_date.date()}"
