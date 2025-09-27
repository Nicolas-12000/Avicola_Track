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
