from rest_framework import serializers
from .models import Farm, Shed


class ShedSerializer(serializers.ModelSerializer):
    occupancy_percentage = serializers.ReadOnlyField()
    current_occupancy = serializers.ReadOnlyField()

    class Meta:
        model = Shed
        fields = ['id', 'name', 'capacity', 'farm', 'assigned_worker', 'current_occupancy', 'occupancy_percentage']
from rest_framework import serializers
from .models import Farm


class FarmSerializer(serializers.ModelSerializer):
    class Meta:
        model = Farm
        fields = ['id', 'name', 'location', 'farm_manager', 'total_capacity', 'active_sheds', 'created_at']
        read_only_fields = ['total_capacity', 'active_sheds', 'created_at']
