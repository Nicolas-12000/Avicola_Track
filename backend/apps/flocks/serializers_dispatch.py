from rest_framework import serializers
from .models import DispatchRecord


class DispatchRecordSerializer(serializers.ModelSerializer):
    flock_info = serializers.SerializerMethodField()

    class Meta:
        model = DispatchRecord
        fields = [
            'id', 'flock', 'flock_info',
            'dispatch_date', 'day_number', 'manifest_number', 'shed_name',
            # Cantidades
            'males_count', 'females_count', 'total_birds',
            # Peso granja
            'farm_avg_weight', 'farm_total_kg',
            # Planta proceso
            'plant_birds', 'plant_missing', 'drowned',
            'plant_avg_weight', 'plant_total_kg', 'plant_shrinkage_grams',
            # Venta
            'sale_birds', 'sale_discount_kg', 'sale_total_kg',
            'sale_avg_weight', 'total_shrinkage_grams',
            # Otros
            'observations', 'recorded_by',
            'client_id', 'sync_status', 'created_by_device',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'day_number', 'plant_shrinkage_grams', 'total_shrinkage_grams',
            'created_at', 'updated_at',
        ]

    def get_flock_info(self, obj):
        return str(obj.flock) if obj.flock else None

    def validate(self, data):
        flock = data.get('flock')
        total_birds = data.get('total_birds', 0)
        males = data.get('males_count', 0)
        females = data.get('females_count', 0)

        # Auto-calcular total si no se proporcionó
        if not total_birds and (males or females):
            data['total_birds'] = (males or 0) + (females or 0)
            total_birds = data['total_birds']

        # Validar que no excedan cantidad actual
        if flock and total_birds > flock.current_quantity:
            raise serializers.ValidationError(
                f'Total de pollos a despachar ({total_birds}) excede la cantidad actual del lote ({flock.current_quantity})'
            )

        return data


class DispatchRecordCreateSerializer(serializers.Serializer):
    """Serializer simplificado para crear despachos desde la app móvil"""
    flock_id = serializers.IntegerField()
    dispatch_date = serializers.DateField()
    manifest_number = serializers.CharField(max_length=50)
    males_count = serializers.IntegerField(default=0)
    females_count = serializers.IntegerField(default=0)
    total_birds = serializers.IntegerField(required=False)
    farm_avg_weight = serializers.DecimalField(max_digits=8, decimal_places=2)
    farm_total_kg = serializers.DecimalField(max_digits=10, decimal_places=2)

    # Opcionales - se llenan después al recibir datos de planta
    plant_birds = serializers.IntegerField(required=False, allow_null=True)
    plant_missing = serializers.IntegerField(default=0)
    drowned = serializers.IntegerField(default=0)
    plant_avg_weight = serializers.DecimalField(max_digits=8, decimal_places=4, required=False, allow_null=True)
    plant_total_kg = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, allow_null=True)

    sale_birds = serializers.IntegerField(required=False, allow_null=True)
    sale_discount_kg = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    sale_total_kg = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, allow_null=True)
    sale_avg_weight = serializers.DecimalField(max_digits=8, decimal_places=6, required=False, allow_null=True)

    observations = serializers.CharField(required=False, allow_blank=True, default='')
    client_id = serializers.CharField(required=False, allow_blank=True)
