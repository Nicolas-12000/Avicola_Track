from rest_framework import serializers
from .models import NotificationLog


class NotificationLogSerializer(serializers.ModelSerializer):
    """Serializer para logs de notificaciones"""
    alarm_details = serializers.SerializerMethodField()
    recipient_name = serializers.SerializerMethodField()
    is_read = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = NotificationLog
        fields = [
            'id',
            'alarm',
            'alarm_details',
            'recipient',
            'recipient_name',
            'notification_type',
            'status',
            'error_message',
            'read_at',
            'is_read',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields
    
    def get_alarm_details(self, obj):
        if obj.alarm:
            alarm = obj.alarm
            resolved_by = None
            if getattr(alarm, 'resolved_by', None):
                rb = alarm.resolved_by
                resolved_by = f"{getattr(rb, 'first_name', '')} {getattr(rb, 'last_name', '')}".strip() or getattr(rb, 'username', None)

            return {
                'id': alarm.id,
                'type': alarm.alarm_type,
                'description': alarm.description,
                'priority': alarm.priority,
                'status': alarm.status,
                'resolved_by': resolved_by,
                'resolved_at': alarm.resolved_at.isoformat() if getattr(alarm, 'resolved_at', None) else None,
                'resolution_notes': alarm.resolution_notes,
            }
        return None
    
    def get_recipient_name(self, obj):
        if obj.recipient:
            return f"{obj.recipient.first_name} {obj.recipient.last_name}".strip() or obj.recipient.username
        return None
