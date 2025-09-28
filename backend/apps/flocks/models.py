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


class MortalityCause(BaseModel):
	"""Catálogo de causas de mortalidad"""
	name = models.CharField(max_length=100, unique=True)
	category = models.CharField(max_length=50, choices=[
		('DISEASE', 'Enfermedad'),
		('ENVIRONMENTAL', 'Ambiental'),
		('NUTRITIONAL', 'Nutricional'),
		('UNKNOWN', 'Desconocida'),
		('OTHER', 'Otra'),
	])
	requires_veterinary = models.BooleanField(default=False)
	is_active = models.BooleanField(default=True)


class MortalityRecord(BaseModel):
	"""Registro de mortalidad con actualización automática del lote"""
	flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='mortality_records')
	date = models.DateField()
	deaths = models.PositiveIntegerField()
	cause = models.ForeignKey(MortalityCause, on_delete=models.SET_NULL, null=True, blank=True)
	recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

	# Campos para análisis
	temperature = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
	notes = models.TextField(blank=True)

	client_id = models.CharField(max_length=50, null=True, blank=True)
	sync_status = models.CharField(max_length=20, default='SYNCED')
	created_by_device = models.CharField(max_length=100, null=True, blank=True)

	class Meta:
		unique_together = ['flock', 'date']

	def save(self, *args, **kwargs):
		is_new = not self.pk

		if is_new:
			# Validar que no exceda cantidad actual
			if self.deaths > self.flock.current_quantity:
				from django.core.exceptions import ValidationError
				raise ValidationError(
					f"Mortalidad ({self.deaths}) excede cantidad actual del lote ({self.flock.current_quantity})"
				)

			# Actualizar lote
			self.flock.current_quantity -= self.deaths
			self.flock.save(update_fields=['current_quantity'])

		super().save(*args, **kwargs)

		# Verificar alarmas después de guardar
		if is_new:
			try:
				self._check_mortality_alarms()
			except Exception:
				# no dejar que una falla en alarmas rompa el guardado
				pass

	def _check_mortality_alarms(self):
		"""Verificar si debe generar alarma por mortalidad alta"""
		from datetime import timedelta
		from django.core.exceptions import ObjectDoesNotExist

		original_quantity = self.flock.current_quantity + self.deaths
		if original_quantity == 0:
			return

		daily_mortality_rate = (self.deaths / original_quantity) * 100

		# Obtener configuración de alarma de la granja
		try:
			from apps.alarms.models import AlarmConfiguration, Alarm
		except Exception:
			return

		config = AlarmConfiguration.objects.filter(
			alarm_type='MORTALITY',
			farm=self.flock.shed.farm,
			is_active=True
		).first()

		if config and daily_mortality_rate >= config.threshold_value:
			priority = 'HIGH' if daily_mortality_rate >= (getattr(config, 'critical_threshold', None) or config.threshold_value * 2) else 'MEDIUM'

			Alarm.objects.create(
				alarm_type='MORTALITY',
				description=f'Mortalidad alta en {self.flock.shed.name}: {daily_mortality_rate:.1f}% (umbral: {config.threshold_value}%)',
				priority=priority,
				flock=self.flock
			)


class SyncConflict(BaseModel):
	"""Registro de conflictos detectados durante sincronización offline"""
	source = models.CharField(max_length=50)  # e.g. 'daily_weight', 'mortality'
	client_id = models.CharField(max_length=100, null=True, blank=True)
	payload = models.JSONField()
	resolution = models.CharField(max_length=50, null=True, blank=True)  # e.g. 'manual', 'discarded', 'merged'
	resolved_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
	resolved_at = models.DateTimeField(null=True, blank=True)

	# Optional link to domain objects
	flock = models.ForeignKey(Flock, null=True, blank=True, on_delete=models.SET_NULL)

	class Meta:
		indexes = [models.Index(fields=['source', 'client_id']), models.Index(fields=['resolved_at'])]
