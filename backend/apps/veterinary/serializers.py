from rest_framework import serializers
from .models import (
    VeterinaryVisit,
    VaccinationRecord,
    Medication,
    Disease,
    BiosecurityChecklist
)


class VeterinaryVisitSerializer(serializers.ModelSerializer):
    # Expose FK fields with _id suffix for frontend compatibility
    farm_id = serializers.PrimaryKeyRelatedField(source='farm', read_only=True)
    veterinarian_id = serializers.PrimaryKeyRelatedField(source='veterinarian', read_only=True)
    flock_ids = serializers.PrimaryKeyRelatedField(
        source='flocks',
        many=True,
        read_only=True
    )

    class Meta:
        model = VeterinaryVisit
        fields = [
            'id', 'farm_id', 'farm', 'veterinarian_id', 'veterinarian',
            'flock_ids', 'flocks', 'visit_date', 'expected_duration_days',
            'visit_type', 'reason', 'diagnosis', 'treatment',
            'prescribed_medications', 'notes', 'photo_urls', 'status',
            'completed_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ('created_at', 'updated_at', 'farm_id', 'veterinarian_id', 'flock_ids')
        extra_kwargs = {
            'farm': {'write_only': True},
            'veterinarian': {'write_only': True},
            'flocks': {'write_only': True},
        }


class VaccinationRecordSerializer(serializers.ModelSerializer):
    flock_id = serializers.PrimaryKeyRelatedField(source='flock', read_only=True)

    class Meta:
        model = VaccinationRecord
        fields = [
            'id', 'flock_id', 'flock', 'vaccine_name', 'vaccine_type',
            'scheduled_date', 'applied_date', 'applied_by',
            'administration_route', 'dosage', 'dosage_unit', 'bird_count',
            'status', 'notes', 'batch_number', 'expiration_date',
            'created_at', 'updated_at'
        ]
        read_only_fields = ('created_at', 'updated_at', 'flock_id')
        extra_kwargs = {
            'flock': {'write_only': True},
        }


class MedicationSerializer(serializers.ModelSerializer):
    flock_id = serializers.PrimaryKeyRelatedField(source='flock', read_only=True)
    prescribed_by = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Medication
        fields = [
            'id', 'flock_id', 'flock', 'medication_name', 'medication_type',
            'active_ingredient', 'start_date', 'end_date', 'duration_days',
            'dosage', 'dosage_unit', 'administration_route', 'frequency',
            'prescribed_by', 'reason', 'withdrawal_period_days',
            'withdrawal_end_date', 'status', 'notes', 'application_dates',
            'created_at', 'updated_at'
        ]
        read_only_fields = ('created_at', 'updated_at', 'flock_id')
        extra_kwargs = {
            'flock': {'write_only': True},
        }


class DiseaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Disease
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at')


class BiosecurityChecklistSerializer(serializers.ModelSerializer):
    farm_id = serializers.PrimaryKeyRelatedField(source='farm', read_only=True)
    shed_id = serializers.PrimaryKeyRelatedField(source='shed', read_only=True)
    performed_by = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = BiosecurityChecklist
        fields = [
            'id', 'farm_id', 'farm', 'shed_id', 'shed', 'checklist_type',
            'performed_date', 'performed_by', 'status',
            'items', 'compliance_score', 'notes', 'photo_urls',
            'corrective_actions', 'corrective_actions_deadline',
            'created_at', 'updated_at'
        ]
        read_only_fields = ('created_at', 'updated_at', 'farm_id', 'shed_id')
        extra_kwargs = {
            'farm': {'write_only': True},
            'shed': {'write_only': True, 'required': False},
        }
