from rest_framework import serializers
from .models import DailyRecord


class DailyRecordSerializer(serializers.ModelSerializer):
    total_mortality = serializers.SerializerMethodField()
    total_process_output = serializers.SerializerMethodField()
    total_balance = serializers.SerializerMethodField()
    total_feed_consumed_kg = serializers.SerializerMethodField()

    class Meta:
        model = DailyRecord
        fields = [
            'id', 'flock', 'date', 'week_number', 'day_number',
            # Mortalidad
            'mortality_male', 'mortality_female', 'total_mortality',
            # Salida a proceso
            'process_output_male', 'process_output_female', 'total_process_output',
            # Saldo
            'balance_male', 'balance_female', 'total_balance',
            # Consumo alimento
            'feed_consumed_kg_male', 'feed_consumed_kg_female', 'total_feed_consumed_kg',
            'feed_per_bird_gr_male', 'feed_per_bird_gr_female',
            'accumulated_feed_per_bird_gr_male', 'accumulated_feed_per_bird_gr_female',
            # Peso
            'weight_male', 'weight_female',
            # Ganancia peso
            'weekly_weight_gain_male', 'weekly_weight_gain_female',
            'daily_avg_weight_gain_male', 'daily_avg_weight_gain_female',
            # Conversión
            'feed_conversion_male', 'feed_conversion_female',
            # Otros
            'temperature', 'notes', 'recorded_by',
            'client_id', 'sync_status', 'created_by_device',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'week_number', 'day_number',
            'feed_per_bird_gr_male', 'feed_per_bird_gr_female',
            'feed_conversion_male', 'feed_conversion_female',
            'created_at', 'updated_at',
        ]

    def get_total_mortality(self, obj):
        return (obj.mortality_male or 0) + (obj.mortality_female or 0)

    def get_total_process_output(self, obj):
        return (obj.process_output_male or 0) + (obj.process_output_female or 0)

    def get_total_balance(self, obj):
        return (obj.balance_male or 0) + (obj.balance_female or 0)

    def get_total_feed_consumed_kg(self, obj):
        return float(obj.feed_consumed_kg_male or 0) + float(obj.feed_consumed_kg_female or 0)

    def validate(self, data):
        flock = data.get('flock')
        date = data.get('date')

        # Verificar que no exista registro para ese día (excepto update)
        if self.instance is None:
            if DailyRecord.objects.filter(flock=flock, date=date).exists():
                raise serializers.ValidationError('Ya existe un registro diario para este lote en esta fecha')

        return data


class DailyRecordCreateSerializer(serializers.Serializer):
    """Serializer simplificado para crear registros diarios desde la app móvil"""
    flock_id = serializers.IntegerField()
    date = serializers.DateField()
    mortality_male = serializers.IntegerField(default=0)
    mortality_female = serializers.IntegerField(default=0)
    process_output_male = serializers.IntegerField(default=0)
    process_output_female = serializers.IntegerField(default=0)
    feed_consumed_kg_male = serializers.DecimalField(max_digits=8, decimal_places=2, default=0)
    feed_consumed_kg_female = serializers.DecimalField(max_digits=8, decimal_places=2, default=0)
    weight_male = serializers.DecimalField(max_digits=8, decimal_places=2, required=False, allow_null=True)
    weight_female = serializers.DecimalField(max_digits=8, decimal_places=2, required=False, allow_null=True)
    temperature = serializers.DecimalField(max_digits=4, decimal_places=1, required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    client_id = serializers.CharField(required=False, allow_blank=True)


class BulkDailyRecordSyncSerializer(serializers.Serializer):
    daily_records = DailyRecordCreateSerializer(many=True)
