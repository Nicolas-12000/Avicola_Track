from django.db import models
from django.utils import timezone
from django.conf import settings

from apps.farms.models import Shed
from django.conf import settings


class BaseModel(models.Model):
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		abstract = True


class Flock(BaseModel):
	"""Lote de pollos con control de estados"""
	GENDER_CHOICES = [
		('M', 'Macho'),
		('F', 'Hembra'),
		('X', 'Mixto'),
	]
	STATUS_CHOICES = [
		('ACTIVE', 'Activo'),
		('SOLD', 'Vendido'),
		('FINISHED', 'Terminado'),
		('TRANSFERRED', 'Transferido'),
	]

	# Datos iniciales del lote
	arrival_date = models.DateField()
	initial_quantity = models.PositiveIntegerField()
	current_quantity = models.PositiveIntegerField()
	initial_weight = models.DecimalField(max_digits=5, decimal_places=2)
	breed = models.CharField(max_length=50)
	gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
	supplier = models.CharField(max_length=100)

	# Relaciones
	shed = models.ForeignKey(Shed, on_delete=models.CASCADE, related_name='flocks')
	status = models.CharField(max_length=12, choices=STATUS_CHOICES, default='ACTIVE')
	created_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name='created_flocks')

	def __str__(self):
		return f"Lote {self.id} - {self.breed} ({self.shed.name})"

	# Campos calculados útiles
	@property
	def current_age_days(self):
		return (timezone.now().date() - self.arrival_date).days

	@property
	def survival_rate(self):
		if self.initial_quantity == 0:
			return 0
		return (self.current_quantity / self.initial_quantity) * 100

	def save(self, *args, **kwargs):
		# Auto-setear current_quantity en creación
		if not self.pk and (self.current_quantity is None or self.current_quantity == 0):
			self.current_quantity = self.initial_quantity
		super().save(*args, **kwargs)


class BreedReference(BaseModel):
	"""Tabla de referencia de peso por raza y edad (días)"""
	breed = models.CharField(max_length=100)
	age_days = models.PositiveIntegerField()
	expected_weight = models.DecimalField(max_digits=6, decimal_places=2)

	class Meta:
		unique_together = ['breed', 'age_days']


class DailyWeightRecord(BaseModel):
	flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='weight_records')
	date = models.DateField()
	average_weight = models.DecimalField(max_digits=6, decimal_places=2)
	sample_size = models.PositiveIntegerField(default=10)
	recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

	expected_weight = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
	deviation_percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)

	client_id = models.CharField(max_length=50, null=True, blank=True)
	sync_status = models.CharField(max_length=20, default='SYNCED')
	created_by_device = models.CharField(max_length=100, null=True, blank=True)

	class Meta:
		unique_together = ['flock', 'date']

	def save(self, *args, **kwargs):
		if not self.expected_weight:
			self.expected_weight = self._calculate_expected_weight()

		if self.expected_weight and self.expected_weight != 0:
			deviation = abs(self.average_weight - self.expected_weight)
			try:
				self.deviation_percentage = (deviation / self.expected_weight) * 100
			except Exception:
				self.deviation_percentage = None

		super().save(*args, **kwargs)

	def _calculate_expected_weight(self):
		age_days = (self.date - self.flock.arrival_date).days
		reference = BreedReference.objects.filter(
			breed=self.flock.breed,
			age_days=age_days
		).first()

		return reference.expected_weight if reference else None
