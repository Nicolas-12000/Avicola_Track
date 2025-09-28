from django.db import models
from django.utils import timezone
from datetime import timedelta

from apps.farms.models import Farm, Shed


class InventoryItem(models.Model):
	"""Inventario inteligente por granja/galpón con métricas automáticas"""
	UNIT_CHOICES = [
		('KG', 'Kilogramos'),
		('TON', 'Toneladas'),
		('BAG', 'Sacos'),
		('LB', 'Libras')
	]

	name = models.CharField(max_length=100)
	description = models.TextField(blank=True)
	current_stock = models.DecimalField(max_digits=12, decimal_places=2, default=0)
	unit = models.CharField(max_length=30, choices=UNIT_CHOICES)
	minimum_stock = models.DecimalField(max_digits=10, decimal_places=2, default=0)

	farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='inventory')
	shed = models.ForeignKey(Shed, on_delete=models.CASCADE, null=True, blank=True, related_name='inventory')

	daily_avg_consumption = models.DecimalField(max_digits=8, decimal_places=2, default=0)
	last_restock_date = models.DateField(null=True, blank=True)
	last_consumption_date = models.DateField(null=True, blank=True)

	alert_threshold_days = models.PositiveIntegerField(default=5)
	critical_threshold_days = models.PositiveIntegerField(default=2)

	class Meta:
		unique_together = ['name', 'farm', 'shed']

	def __str__(self):
		return f"{self.name} - {self.location_display}"

	@property
	def location_display(self):
		if self.shed:
			return f"{self.shed.name} ({self.farm.name})"
		return f"General - {self.farm.name}"

	@property
	def projected_stockout_date(self):
		if self.daily_avg_consumption and self.daily_avg_consumption > 0:
			days_remaining = float(self.current_stock) / float(self.daily_avg_consumption)
			return timezone.now().date() + timedelta(days=int(days_remaining))
		return None

	@property
	def stock_status(self):
		if float(self.current_stock) <= 0:
			return {'status': 'OUT_OF_STOCK', 'color': 'red', 'message': 'Sin stock'}

		if float(self.daily_avg_consumption) <= 0:
			return {'status': 'UNKNOWN', 'color': 'gray', 'message': 'Sin histórico'}

		days_remaining = float(self.current_stock) / float(self.daily_avg_consumption)

		if days_remaining <= self.critical_threshold_days:
			return {'status': 'CRITICAL', 'color': 'red', 'message': f'{days_remaining:.1f} días'}
		elif days_remaining <= self.alert_threshold_days:
			return {'status': 'LOW', 'color': 'orange', 'message': f'{days_remaining:.1f} días'}
		else:
			return {'status': 'NORMAL', 'color': 'green', 'message': f'{days_remaining:.1f} días'}

	def update_consumption_metrics(self):
		end_date = timezone.now().date()
		start_date = end_date - timedelta(days=30)

		total = self.consumption_records.filter(date__range=[start_date, end_date]).aggregate(
			total=models.Sum('quantity_consumed')
		)['total'] or 0

		# Promedio por día
		self.daily_avg_consumption = float(total) / 30 if total else 0

		last = self.consumption_records.order_by('-date').first()
		if last:
			self.last_consumption_date = last.date

		self.save(update_fields=['daily_avg_consumption', 'last_consumption_date'])


class InventoryConsumptionRecord(models.Model):
	"""Registro diario de consumo de un item de inventario"""
	inventory_item = models.ForeignKey(InventoryItem, on_delete=models.CASCADE, related_name='consumption_records')
	date = models.DateField()
	quantity_consumed = models.DecimalField(max_digits=12, decimal_places=2)

	class Meta:
		unique_together = ['inventory_item', 'date']

	def save(self, *args, **kwargs):
		super().save(*args, **kwargs)
		# Después de guardar, actualizar métricas en el item
		try:
			self.inventory_item.update_consumption_metrics()
		except Exception:
			pass


# Create your models here.
