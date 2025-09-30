from rest_framework import serializers
from .models import AlarmConfiguration, Alarm


class AlarmConfigurationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AlarmConfiguration
        fields = '__all__'


class AlarmSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alarm
        fields = '__all__'
        read_only_fields = (
            'id', 'created_at', 'updated_at', 'status'
        )

    def validate(self, data):
        # Ensure at least one source reference exists or a farm/flock/shed
        if not (data.get('source_type') or data.get('farm') or data.get('flock') or data.get('shed')):
            raise serializers.ValidationError('Se requiere al menos una referencia de origen o ubicación (farm/flock/shed)')
        return data
