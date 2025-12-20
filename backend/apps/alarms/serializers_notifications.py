from rest_framework import serializers
from .models import NotificationLog


class NotificationLogSerializer(serializers.ModelSerializer):
    """Serializer para logs de notificaciones"""
    alarm_details = serializers.SerializerMethodField()
    recipient_name = serializers.SerializerMethodField()
    
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
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields
    
    def get_alarm_details(self, obj):
        if obj.alarm:
            return {
                'id': obj.alarm.id,
                'type': obj.alarm.alarm_type,
                'description': obj.alarm.description,
                'priority': obj.alarm.priority,
                'status': obj.alarm.status,
            }
        return None
    
    def get_recipient_name(self, obj):
        if obj.recipient:
            return f"{obj.recipient.first_name} {obj.recipient.last_name}".strip() or obj.recipient.username
        return None
