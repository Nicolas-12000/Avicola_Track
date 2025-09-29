from rest_framework import serializers
from .models import SyncConflict


class SyncConflictSerializer(serializers.ModelSerializer):
    class Meta:
        model = SyncConflict
        fields = [
            'id', 'conflict_type', 'record_type', 'farm', 'server_data', 'client_data',
            'device_info', 'resolution_status', 'resolved_by', 'resolved_at', 'resolution_data',
            'resolution_notes', 'reported_by', 'priority', 'created_at', 'updated_at'
        ]
        read_only_fields = (
            'id', 'resolution_status', 'resolved_by', 'resolved_at', 'resolution_data',
            'created_at', 'updated_at', 'reported_by'
        )

    def validate(self, data):
        # Ensure farm is provided for conflicts
        if not data.get('farm'):
            raise serializers.ValidationError('El campo farm es obligatorio para crear un conflicto')
        return data

