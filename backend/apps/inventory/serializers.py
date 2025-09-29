from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field, OpenApiTypes

from .models import InventoryItem, InventoryConsumptionRecord


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

