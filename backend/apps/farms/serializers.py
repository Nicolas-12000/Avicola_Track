from rest_framework import serializers
from django.db.models import Count
from .models import Farm, Shed


class ShedSerializer(serializers.ModelSerializer):
    occupancy_percentage = serializers.ReadOnlyField()
    current_occupancy = serializers.ReadOnlyField()
    assigned_worker_name = serializers.SerializerMethodField()

    class Meta:
        model = Shed
        fields = [
            'id', 'name', 'capacity', 'farm', 'assigned_worker',
            'assigned_worker_name', 'current_occupancy', 'occupancy_percentage',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['current_occupancy', 'occupancy_percentage', 'created_at', 'updated_at']

    def get_assigned_worker_name(self, obj):
        # Works without extra query when select_related('assigned_worker') is used
        if obj.assigned_worker:
            return f"{obj.assigned_worker.first_name} {obj.assigned_worker.last_name}".strip() or obj.assigned_worker.username
        return None


class FarmSerializer(serializers.ModelSerializer):
    farm_manager_name = serializers.SerializerMethodField()
    sheds_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Farm
        fields = [
            'id', 'name', 'location', 'farm_manager', 'farm_manager_name',
            'total_capacity', 'active_sheds', 'sheds_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['total_capacity', 'active_sheds', 'created_at', 'updated_at']

    def get_farm_manager_name(self, obj):
        # Works without extra query when select_related('farm_manager') is used
        if obj.farm_manager:
            return f"{obj.farm_manager.first_name} {obj.farm_manager.last_name}".strip() or obj.farm_manager.username
        return None

    def get_sheds_count(self, obj):
        # Use prefetched sheds if available (avoids N+1), otherwise fallback to count()
        if hasattr(obj, '_prefetched_objects_cache') and 'sheds' in obj._prefetched_objects_cache:
            return len(obj._prefetched_objects_cache['sheds'])
        return obj.sheds.count()
