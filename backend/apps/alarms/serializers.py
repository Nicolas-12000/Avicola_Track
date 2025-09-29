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
