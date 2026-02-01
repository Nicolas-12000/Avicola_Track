from django.contrib import admin
from .models import (
    VeterinaryVisit,
    VaccinationRecord,
    Medication,
    Disease,
    BiosecurityChecklist
)


@admin.register(VeterinaryVisit)
class VeterinaryVisitAdmin(admin.ModelAdmin):
    list_display = ('id', 'farm', 'veterinarian', 'visit_date', 'visit_type', 'status', 'expected_duration_days')
    list_filter = ('visit_type', 'status', 'visit_date', 'farm')
    search_fields = ('farm__name', 'veterinarian__username', 'diagnosis', 'reason')
    date_hierarchy = 'visit_date'
    filter_horizontal = ('flocks',)


@admin.register(VaccinationRecord)
class VaccinationRecordAdmin(admin.ModelAdmin):
    list_display = ('id', 'flock', 'vaccine_name', 'scheduled_date', 'status')
    list_filter = ('vaccine_type', 'status', 'scheduled_date')
    search_fields = ('vaccine_name', 'flock__breed')
    date_hierarchy = 'scheduled_date'


@admin.register(Medication)
class MedicationAdmin(admin.ModelAdmin):
    list_display = ('id', 'flock', 'medication_name', 'start_date', 'status')
    list_filter = ('medication_type', 'status', 'start_date')
    search_fields = ('medication_name', 'flock__breed')
    date_hierarchy = 'start_date'


@admin.register(Disease)
class DiseaseAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'category', 'severity', 'is_notifiable')
    list_filter = ('category', 'severity', 'is_notifiable')
    search_fields = ('name', 'scientific_name')


@admin.register(BiosecurityChecklist)
class BiosecurityChecklistAdmin(admin.ModelAdmin):
    list_display = ('id', 'farm', 'checklist_type', 'performed_date', 'status', 'compliance_score')
    list_filter = ('checklist_type', 'status', 'performed_date')
    search_fields = ('farm__name',)
    date_hierarchy = 'performed_date'
