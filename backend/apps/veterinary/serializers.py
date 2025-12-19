from rest_framework import serializers
from .models import (
    VeterinaryVisit,
    VaccinationRecord,
    Medication,
    Disease,
    BiosecurityChecklist
)


class VeterinaryVisitSerializer(serializers.ModelSerializer):
    class Meta:
        model = VeterinaryVisit
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class VaccinationRecordSerializer(serializers.ModelSerializer):
    class Meta:
        model = VaccinationRecord
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class MedicationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medication
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class DiseaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Disease
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class BiosecurityChecklistSerializer(serializers.ModelSerializer):
    class Meta:
        model = BiosecurityChecklist
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')
