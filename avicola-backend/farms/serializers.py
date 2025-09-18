from rest_framework import serializers
from .models import Farm, House
from users.serializers import UserSerializer
from users.models import User


class FarmSerializer(serializers.ModelSerializer):
    responsible_details = UserSerializer(source='responsible', read_only=True)
    responsible = serializers.PrimaryKeyRelatedField(queryset=User.objects.filter(role__in=['ADMIN', 'VETERINARIAN']))

    class Meta:
        model = Farm
        fields = '__all__'
        read_only_fields = ('created_at',)


class HouseSerializer(serializers.ModelSerializer):
    farm_name = serializers.CharField(source='farm.name', read_only=True)
    responsible_details = UserSerializer(source='responsible', read_only=True)
    responsible = serializers.PrimaryKeyRelatedField(queryset=User.objects.filter(role='HOUSEMAN'))

    class Meta:
        model = House
        fields = '__all__'

    def validate(self, data):
        capacity = data.get('capacity', getattr(self.instance, 'capacity', None))
        current_capacity = data.get('current_capacity', getattr(self.instance, 'current_capacity', 0))
        if capacity is not None and current_capacity is not None and current_capacity > capacity:
            raise serializers.ValidationError({'current_capacity': 'La capacidad actual no puede ser mayor que la capacidad máxima.'})
        return data
