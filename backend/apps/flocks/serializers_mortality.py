from rest_framework import serializers


class MortalityRecordSerializer(serializers.Serializer):
    flock_id = serializers.IntegerField()
    date = serializers.DateField()
    deaths = serializers.IntegerField()
    cause_name = serializers.CharField(required=False, allow_blank=True)
    temperature = serializers.DecimalField(max_digits=4, decimal_places=1, required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True)
    client_id = serializers.CharField(required=False, allow_blank=True)


class MortalityBulkRequestSerializer(serializers.Serializer):
    mortality_records = MortalityRecordSerializer(many=True)


class MortalityBulkDetailSerializer(serializers.Serializer):
    client_id = serializers.CharField(required=False, allow_blank=True)
    server_id = serializers.IntegerField(required=False, allow_null=True)
    status = serializers.ChoiceField(choices=[('success', 'success'), ('error', 'error')])
    action = serializers.CharField(required=False)
    error = serializers.CharField(required=False, allow_blank=True)


class MortalityBulkResultSerializer(serializers.Serializer):
    total = serializers.IntegerField()
    successful = serializers.IntegerField()
    errors = serializers.IntegerField()
    details = MortalityBulkDetailSerializer(many=True)
