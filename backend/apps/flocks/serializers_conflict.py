from rest_framework import serializers


class SyncConflictSerializer(serializers.Serializer):
    id = serializers.IntegerField(read_only=True)
    source = serializers.CharField()
    client_id = serializers.CharField(allow_blank=True, required=False)
    payload = serializers.JSONField()
    resolution = serializers.CharField(allow_blank=True, required=False)
    flock = serializers.IntegerField(required=False, allow_null=True)
    resolved_by = serializers.IntegerField(required=False, allow_null=True)
    resolved_at = serializers.DateTimeField(required=False, allow_null=True)


class ResolveConflictSerializer(serializers.Serializer):
    resolution = serializers.ChoiceField(choices=[('manual', 'manual'), ('discarded', 'discarded'), ('merged', 'merged')])
    note = serializers.CharField(required=False, allow_blank=True)
