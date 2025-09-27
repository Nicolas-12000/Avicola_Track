from django.db import models
from django.conf import settings


class BaseModel(models.Model):
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		abstract = True


class Farm(BaseModel):
	name = models.CharField(max_length=100, unique=True)
	location = models.TextField()
	farm_manager = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.CASCADE,
		related_name='managed_farms',
		limit_choices_to={'role__name': 'Administrador de Granja'}
	)

	total_capacity = models.PositiveIntegerField(default=0)
	active_sheds = models.PositiveIntegerField(default=0)

	def __str__(self):
		return self.name

	def update_farm_stats(self):
		sheds = getattr(self, 'sheds', []).all()
		self.total_capacity = sum(getattr(s, 'capacity', 0) for s in sheds)
		self.active_sheds = sum(1 for s in sheds if getattr(s, 'assigned_worker', None) is not None)
		self.save(update_fields=['total_capacity', 'active_sheds'])


class Shed(BaseModel):
	"""Galpón / Shed model with occupancy helpers and assigned worker"""
	name = models.CharField(max_length=100)
	capacity = models.PositiveIntegerField()
	farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='sheds')

	# Un galponero por galpón (puede tener múltiples galpones)
	assigned_worker = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.SET_NULL,
		null=True,
		blank=True,
		related_name='assigned_sheds',
		limit_choices_to={'role__name': 'Galponero'}
	)

	class Meta:
		unique_together = ['name', 'farm']
		indexes = [models.Index(fields=['farm', 'name']), models.Index(fields=['assigned_worker'])]

	def __str__(self):
		return f"{self.name} ({self.farm.name})"

	@property
	def current_occupancy(self):
		"""Ocupación actual calculada en tiempo real"""
		active_flocks = self.sheds_related_flocks() if False else self.flocks.filter(status='ACTIVE')
		return sum(getattr(flock, 'current_quantity', 0) for flock in active_flocks)

	def sheds_related_flocks(self):
		# helper placeholder - kept for compatibility if needed
		return self.flocks.all()

	@property
	def occupancy_percentage(self):
		"""Porcentaje de ocupación"""
		if self.capacity == 0:
			return 0
		return (self.current_occupancy / self.capacity) * 100

	@property
	def available_capacity(self):
		"""Capacidad disponible"""
		return max(0, self.capacity - self.current_occupancy)

