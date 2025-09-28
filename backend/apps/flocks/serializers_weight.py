from rest_framework import serializers
from .models import DailyWeightRecord, BreedReference


class BreedReferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = BreedReference
        fields = ['id', 'breed', 'age_days', 'expected_weight']


class DailyWeightSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyWeightRecord
        fields = ['id', 'flock', 'date', 'average_weight', 'sample_size', 'recorded_by', 'expected_weight', 'deviation_percentage', 'client_id']
        read_only_fields = ['expected_weight', 'deviation_percentage']

    def validate(self, data):
        # Ensure one per flock per day (will be enforced by unique_together too)
        if DailyWeightRecord.objects.filter(flock=data['flock'], date=data['date']).exists():
            raise serializers.ValidationError('Ya existe un registro para este lote en la fecha')
        return data


class BulkWeightRecordSerializer(serializers.Serializer):
    flock_id = serializers.IntegerField()
    date = serializers.DateField()
    average_weight = serializers.DecimalField(max_digits=6, decimal_places=2)
    sample_size = serializers.IntegerField(required=False, default=10)
    client_id = serializers.CharField(required=False, allow_blank=True)


class BulkSyncRequestSerializer(serializers.Serializer):
    weight_records = BulkWeightRecordSerializer(many=True)


class BulkSyncDetailSerializer(serializers.Serializer):
    client_id = serializers.CharField(allow_blank=True, required=False)
    server_id = serializers.IntegerField(required=False, allow_null=True)
    status = serializers.ChoiceField(choices=[('created', 'created'), ('averaged', 'averaged'), ('conflict', 'conflict')])
    message = serializers.CharField(required=False, allow_blank=True)


class BulkSyncResultSerializer(serializers.Serializer):
    total = serializers.IntegerField()
    successful = serializers.IntegerField()
    conflicts = serializers.IntegerField()
    errors = serializers.IntegerField()
    details = BulkSyncDetailSerializer(many=True)


# --- Dashboard response serializers (for OpenAPI clarity) ---
class ShedOccupancySerializer(serializers.Serializer):
    current = serializers.IntegerField()
    capacity = serializers.IntegerField()
    percentage = serializers.FloatField()


class ShedFlocksSummarySerializer(serializers.Serializer):
    active_count = serializers.IntegerField()
    avg_age = serializers.FloatField()
    total_birds = serializers.IntegerField()


class ShedDetailSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    farm_name = serializers.CharField()
    galponero = serializers.CharField()
    occupancy = ShedOccupancySerializer()
    flocks = ShedFlocksSummarySerializer()
    last_activity = serializers.DictField(child=serializers.CharField(allow_null=True), required=False)
    status_indicator = serializers.DictField(child=serializers.CharField())


class DashboardResponseSerializer(serializers.Serializer):
    summary = serializers.DictField(child=serializers.IntegerField())
    sheds = ShedDetailSerializer(many=True)
    alerts_count = serializers.IntegerField()
    last_updated = serializers.DateTimeField()