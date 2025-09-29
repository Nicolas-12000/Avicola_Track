from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field, OpenApiTypes

from .models import InventoryItem, InventoryConsumptionRecord, FoodBatch, FoodConsumptionRecord


class InventoryConsumptionRecordSerializer(serializers.ModelSerializer):
	class Meta:
		model = InventoryConsumptionRecord
		fields = ['id', 'inventory_item', 'date', 'quantity_consumed']


class InventoryItemSerializer(serializers.ModelSerializer):
	projected_stockout_date = serializers.SerializerMethodField()
	stock_status = serializers.SerializerMethodField()

	class Meta:
		model = InventoryItem
		fields = [
			'id', 'name', 'description', 'current_stock', 'unit', 'minimum_stock',
			'farm', 'shed', 'daily_avg_consumption', 'last_restock_date', 'last_consumption_date',
			'alert_threshold_days', 'critical_threshold_days', 'projected_stockout_date', 'stock_status'
		]
		read_only_fields = ['daily_avg_consumption', 'last_consumption_date', 'projected_stockout_date', 'stock_status']


	@extend_schema_field(OpenApiTypes.DATE)
	def get_projected_stockout_date(self, obj):
		return obj.projected_stockout_date.isoformat() if obj.projected_stockout_date else None

	@extend_schema_field(OpenApiTypes.OBJECT)
	def get_stock_status(self, obj):
		return obj.stock_status



class BulkStockUpdateSerializer(serializers.Serializer):
	client_id = serializers.CharField(required=False, allow_null=True)
	inventory_id = serializers.IntegerField()
	new_stock = serializers.DecimalField(max_digits=12, decimal_places=2)


class StockAlertSerializer(serializers.Serializer):
	id = serializers.IntegerField()
	name = serializers.CharField()
	location = serializers.CharField()
	current_stock = serializers.DecimalField(max_digits=12, decimal_places=2)
	unit = serializers.CharField()
	status = serializers.DictField()
	projected_stockout = serializers.DateField(allow_null=True)


class FoodBatchSerializer(serializers.ModelSerializer):
	is_depleted = serializers.ReadOnlyField()
	consumption_rate = serializers.ReadOnlyField()
	
	class Meta:
		model = FoodBatch
		fields = [
			'id', 'inventory_item', 'entry_date', 'initial_quantity', 'current_quantity',
			'supplier', 'lot_number', 'expiry_date', 'is_depleted', 'consumption_rate'
		]


class FoodConsumptionRecordSerializer(serializers.ModelSerializer):
	class Meta:
		model = FoodConsumptionRecord
		fields = [
			'id', 'flock', 'inventory_item', 'date', 'quantity_consumed', 
			'fifo_details', 'recorded_by', 'client_id'
		]
		read_only_fields = ['fifo_details', 'recorded_by']

	def validate(self, data):
		# Verificar que no existe registro para el mismo lote e inventario en la fecha
		if FoodConsumptionRecord.objects.filter(
			flock=data['flock'], 
			inventory_item=data['inventory_item'], 
			date=data['date']
		).exists():
			raise serializers.ValidationError('Ya existe un registro de consumo para este lote e item en la fecha especificada')
		return data


class FoodConsumptionRequestSerializer(serializers.Serializer):
	"""Serializer para registrar consumo FIFO"""
	flock_id = serializers.IntegerField()
	inventory_item_id = serializers.IntegerField()
	quantity_consumed = serializers.DecimalField(max_digits=12, decimal_places=2)
	date = serializers.DateField(required=False)
	client_id = serializers.CharField(required=False, allow_null=True)


class BulkFoodConsumptionSerializer(serializers.Serializer):
	"""Serializer para sync masivo de consumo FIFO"""
	consumption_records = FoodConsumptionRequestSerializer(many=True)


class FIFOConsumptionResultSerializer(serializers.Serializer):
	"""Resultado del consumo FIFO"""
	consumption_record_id = serializers.IntegerField()
	fifo_details = serializers.ListField(child=serializers.DictField())
	remaining_stock = serializers.DecimalField(max_digits=12, decimal_places=2)
	

class AddStockSerializer(serializers.Serializer):
	"""Serializer para agregar stock con lote FIFO"""
	quantity = serializers.DecimalField(max_digits=12, decimal_places=2)
	entry_date = serializers.DateField(required=False)
	supplier = serializers.CharField(required=False, allow_blank=True)
	lot_number = serializers.CharField(required=False, allow_blank=True)
	expiry_date = serializers.DateField(required=False, allow_null=True)

