from django.db import models
from django.utils import timezone
from django.conf import settings

from apps.farms.models import Shed, BaseModel


class SyncableRecordModel(BaseModel):
	"""Modelo base para registros sincronizables con campos de auditoría comunes."""
	recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
	client_id = models.CharField(max_length=50, null=True, blank=True)
	sync_status = models.CharField(max_length=20, default='SYNCED')
	created_by_device = models.CharField(max_length=100, null=True, blank=True)

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
		('INACTIVE', 'Inactivo'),
		('SOLD', 'Vendido'),
		('FINISHED', 'Terminado'),
		('TRANSFERRED', 'Transferido'),
	]
	PRODUCTION_STAGE_CHOICES = [
		('BREEDER', 'Rebaño reproductor'),
		('PULLET_FARM', 'Granja de pletinas'),
		('BROODER', 'Casa criadora'),
		('HATCHERY', 'Criadero'),
		('GROW_OUT', 'Granja de engorde'),
		('PROCESSING', 'Procesamiento'),
		('DISTRIBUTION', 'Distribución'),
	]
	PROCESSING_STAGE_CHOICES = [
		('RECEPTION', 'Recepción y Espera'),
		('HANGING', 'Colgado'),
		('STUNNING', 'Aturdimiento y Sacrificio'),
		('BLEEDING', 'Desangrado'),
		('SCALDING', 'Escaldado y Desplumado'),
		('EVISCERATION', 'Eviscerado'),
		('POST_MORTEM', 'Inspección Post-Mortem'),
		('CHILLING', 'Enfriamiento'),
		('CLASSIFICATION', 'Clasificación y Empaque'),
		('STORAGE', 'Almacenamiento y Distribución'),
	]

	# Datos iniciales del lote
	arrival_date = models.DateField()
	initial_quantity = models.PositiveIntegerField()
	current_quantity = models.PositiveIntegerField()
	initial_weight = models.DecimalField(max_digits=6, decimal_places=2)

	# Sub-grupos Machos/Hembras
	initial_quantity_male = models.PositiveIntegerField(default=0, help_text="Cantidad inicial machos")
	initial_quantity_female = models.PositiveIntegerField(default=0, help_text="Cantidad inicial hembras")
	current_quantity_male = models.PositiveIntegerField(default=0, help_text="Cantidad actual machos")
	current_quantity_female = models.PositiveIntegerField(default=0, help_text="Cantidad actual hembras")
	initial_weight_male = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True, help_text="Peso inicial promedio machos (g)")
	initial_weight_female = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True, help_text="Peso inicial promedio hembras (g)")

	# Umbrales personalizables por lote (opcionales)
	weight_alert_low = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
	weight_alert_high = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
	breed = models.CharField(max_length=50)
	gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
	supplier = models.CharField(max_length=100)

	# Etapa de producción
	production_stage = models.CharField(
		max_length=15, choices=PRODUCTION_STAGE_CHOICES, default='GROW_OUT',
		help_text='Etapa del proceso de producción en la que se encuentra el lote'
	)
	processing_stage = models.CharField(
		max_length=15, choices=PROCESSING_STAGE_CHOICES, null=True, blank=True,
		help_text='Sub-etapa de procesamiento (solo cuando production_stage=PROCESSING)'
	)

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
	def current_age_weeks(self):
		"""Edad del lote en semanas (redondeado hacia arriba)"""
		days = self.current_age_days
		return (days // 7) + (1 if days % 7 > 0 else 0) if days > 0 else 0

	@property
	def survival_rate(self):
		if self.initial_quantity == 0:
			return 0
		return (self.current_quantity / self.initial_quantity) * 100

	def save(self, *args, **kwargs):
		# Auto-setear current_quantity en creación
		if not self.pk and (self.current_quantity is None or self.current_quantity == 0):
			self.current_quantity = self.initial_quantity
		
		# Auto-setear cantidades male/female en creación
		if not self.pk:
			if self.initial_quantity_male == 0 and self.initial_quantity_female == 0:
				# Si no se especificaron sub-grupos, todo va al género indicado
				if self.gender == 'M':
					self.initial_quantity_male = self.initial_quantity
					self.initial_quantity_female = 0
				elif self.gender == 'F':
					self.initial_quantity_male = 0
					self.initial_quantity_female = self.initial_quantity
				else:
					# Mixto: dividir mitad y mitad
					self.initial_quantity_male = self.initial_quantity // 2
					self.initial_quantity_female = self.initial_quantity - self.initial_quantity_male
			if self.current_quantity_male == 0 and self.current_quantity_female == 0:
				self.current_quantity_male = self.initial_quantity_male
				self.current_quantity_female = self.initial_quantity_female
		
		# Validar capacidad del galpón antes de crear nuevo lote
		if not self.pk:  # Solo en creación
			self._validate_shed_capacity()
		
		super().save(*args, **kwargs)
	
	def _validate_shed_capacity(self):
		"""Validar que el galpón tenga suficiente capacidad para el nuevo lote"""
		if not self.shed or not hasattr(self.shed, 'capacity'):
			return  # Si no hay galpón o capacidad definida, no validar
		
		# Calcular capacidad actual ocupada en el galpón
		current_occupation = Flock.objects.filter(
			shed=self.shed,
			status='ACTIVE'
		).aggregate(
			total=models.Sum('current_quantity')
		)['total'] or 0
		
		# Verificar si el nuevo lote excede la capacidad
		if current_occupation + self.initial_quantity > self.shed.capacity:
			from django.core.exceptions import ValidationError
			raise ValidationError(
				f'El galpón {self.shed.name} no tiene suficiente capacidad. '
				f'Capacidad: {self.shed.capacity}, Ocupado: {current_occupation}, '
				f'Nuevo lote: {self.initial_quantity}'
			)


class BreedReference(BaseModel):
	"""Tabla de referencia de peso y consumo por raza y edad (días) con versionado"""
	breed = models.CharField(max_length=100)
	age_days = models.PositiveIntegerField()
	expected_weight = models.DecimalField(max_digits=6, decimal_places=2)
	expected_consumption = models.DecimalField(max_digits=6, decimal_places=2, default=0)  # gramos/ave/día
	tolerance_range = models.DecimalField(max_digits=5, decimal_places=2, default=10.0)  # porcentaje

	# Versionado para actualizaciones
	version = models.PositiveIntegerField(default=1)
	is_active = models.BooleanField(default=True)
	created_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.CASCADE)

	class Meta:
		unique_together = ['breed', 'age_days', 'version']
		ordering = ['breed', 'age_days']

	@classmethod
	def get_reference_for_flock(cls, flock, date=None):
		"""Obtener referencia para un lote en una fecha específica"""
		if date is None:
			date = timezone.now().date()

		age_days = (date - flock.arrival_date).days

		return cls.objects.filter(
			breed=flock.breed,
			age_days=age_days,
			is_active=True
		).order_by('-version').first()


class DailyWeightRecord(SyncableRecordModel):
	flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='weight_records')
	date = models.DateField()
	average_weight = models.DecimalField(max_digits=6, decimal_places=2)
	sample_size = models.PositiveIntegerField(default=10)

	expected_weight = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
	deviation_percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)

	class Meta:
		unique_together = ['flock', 'date']

	def save(self, *args, **kwargs):
		# Calcular peso esperado y desviación automáticamente
		if not self.expected_weight or self.expected_weight == 0:
			self.expected_weight = self._calculate_expected_weight()

		if self.expected_weight and self.expected_weight > 0:
			deviation = abs(self.average_weight - self.expected_weight)
			try:
				self.deviation_percentage = (deviation / self.expected_weight) * 100
			except Exception:
				self.deviation_percentage = None
		
		# Guardar primero el registro
		super().save(*args, **kwargs)
		
		# Verificar si se debe generar alarma por desviación
		self._check_weight_deviation_alarm()

	def _calculate_expected_weight(self):
		"""Calcular peso esperado usando BreedReference más inteligente"""
		# Usar el método de clase que maneja versionado
		reference = BreedReference.get_reference_for_flock(self.flock, self.date)
		return reference.expected_weight if reference else None
	
	def _check_weight_deviation_alarm(self):
		"""Verificar si el peso está fuera del rango aceptable y generar alarma"""
		if not self.expected_weight or not self.deviation_percentage:
			return
		
		try:
			from apps.alarms.models import AlarmConfiguration, Alarm
		except ImportError:
			return
			
		# Obtener referencia para verificar tolerancia
		reference = BreedReference.get_reference_for_flock(self.flock, self.date)
		if not reference:
			return
			
		tolerance = float(reference.tolerance_range)
		
		# Si la desviación supera la tolerancia, crear alarma
		if float(self.deviation_percentage) > tolerance:
			# Verificar configuración de alarmas de la granja
			config = AlarmConfiguration.objects.filter(
				alarm_type='WEIGHT_DEVIATION',
				farm=self.flock.shed.farm,
				is_active=True
			).first()
			
			if config:
				# Verificar si no existe alarma similar reciente
				recent_alarms = Alarm.objects.filter(
					alarm_type='WEIGHT_DEVIATION',
					entity_type='FLOCK',
					entity_id=self.flock.id,
					status='PENDING',
					created_at__date=self.date
				)
				
				if not recent_alarms.exists():
					priority = 'HIGH' if float(self.deviation_percentage) > (tolerance * 2) else 'MEDIUM'
					
					Alarm.objects.create(
						alarm_type='WEIGHT_DEVIATION',
						entity_type='FLOCK',
						entity_id=self.flock.id,
						priority=priority,
						title=f'Peso fuera de rango - {self.flock}',
						message=f'Peso promedio {self.average_weight}g vs esperado {self.expected_weight}g. Desviación: {self.deviation_percentage:.1f}%',
						farm=self.flock.shed.farm,
						shed=self.flock.shed,
						data={
							'flock_id': self.flock.id,
							'date': self.date.isoformat(),
							'actual_weight': float(self.average_weight),
							'expected_weight': float(self.expected_weight),
							'deviation_percentage': float(self.deviation_percentage),
							'tolerance_range': tolerance,
							'breed': self.flock.breed
						}
					)


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


class MortalityRecord(SyncableRecordModel):
	"""Registro de mortalidad con actualización automática del lote"""
	flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='mortality_records')
	date = models.DateField()
	deaths = models.PositiveIntegerField()
	cause = models.ForeignKey(MortalityCause, on_delete=models.SET_NULL, null=True, blank=True)

	# Campos para análisis
	temperature = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
	notes = models.TextField(blank=True)


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


class FlockSyncConflict(BaseModel):
	"""Registro de conflictos detectados durante sincronización offline de flocks"""
	source = models.CharField(max_length=50)  # e.g. 'daily_weight', 'mortality'
	client_id = models.CharField(max_length=100, null=True, blank=True)
	payload = models.JSONField()
	resolution = models.CharField(max_length=50, null=True, blank=True)  # e.g. 'manual', 'discarded', 'merged'
	resolved_by = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL)
	resolved_at = models.DateTimeField(null=True, blank=True)

	# Optional link to domain objects
	flock = models.ForeignKey(Flock, null=True, blank=True, on_delete=models.SET_NULL)

	class Meta:
		db_table = 'flocks_syncconflict'  # Keep existing table name
		indexes = [models.Index(fields=['source', 'client_id']), models.Index(fields=['resolved_at'])]


class ReferenceImportLog(BaseModel):
	"""Log de importaciones de tablas de referencia"""
	file_name = models.CharField(max_length=255)
	imported_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
	total_rows = models.PositiveIntegerField(default=0)
	successful_imports = models.PositiveIntegerField(default=0)
	updates = models.PositiveIntegerField(default=0)
	errors = models.PositiveIntegerField(default=0)
	error_details = models.JSONField(default=list)


class DailyRecord(SyncableRecordModel):
	"""Registro diario consolidado por lote - replica la hoja CONSUMO DIARIO del Excel"""
	flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='daily_records')
	date = models.DateField()
	week_number = models.PositiveIntegerField(help_text="Número de semana desde llegada")
	day_number = models.PositiveIntegerField(help_text="Día desde llegada (edad)")

	# Mortalidad por sub-grupo
	mortality_male = models.PositiveIntegerField(default=0)
	mortality_female = models.PositiveIntegerField(default=0)

	# Salida a proceso (pollos enviados a planta)
	process_output_male = models.PositiveIntegerField(default=0, help_text="Machos enviados a proceso")
	process_output_female = models.PositiveIntegerField(default=0, help_text="Hembras enviadas a proceso")

	# Saldo de pollitos (calculado: anterior - mortalidad - salida_proceso)
	balance_male = models.PositiveIntegerField(default=0, help_text="Saldo pollitos machos")
	balance_female = models.PositiveIntegerField(default=0, help_text="Saldo pollitos hembras")

	# Consumo de alimento
	feed_consumed_kg_male = models.DecimalField(max_digits=8, decimal_places=2, default=0, help_text="KG alimento consumido machos")
	feed_consumed_kg_female = models.DecimalField(max_digits=8, decimal_places=2, default=0, help_text="KG alimento consumido hembras")
	feed_per_bird_gr_male = models.DecimalField(max_digits=8, decimal_places=2, default=0, help_text="Consumo por pollo machos (gr)")
	feed_per_bird_gr_female = models.DecimalField(max_digits=8, decimal_places=2, default=0, help_text="Consumo por pollo hembras (gr)")
	accumulated_feed_per_bird_gr_male = models.DecimalField(max_digits=8, decimal_places=2, default=0, help_text="Consumo acumulado por pollo machos (gr)")
	accumulated_feed_per_bird_gr_female = models.DecimalField(max_digits=8, decimal_places=2, default=0, help_text="Consumo acumulado por pollo hembras (gr)")

	# Peso
	weight_male = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Peso promedio machos (gr)")
	weight_female = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Peso promedio hembras (gr)")

	# Ganancia de peso
	weekly_weight_gain_male = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Ganancia peso semanal machos (gr)")
	weekly_weight_gain_female = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Ganancia peso semanal hembras (gr)")
	daily_avg_weight_gain_male = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Ganancia peso promedio diario machos (gr)")
	daily_avg_weight_gain_female = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True, help_text="Ganancia peso promedio diario hembras (gr)")

	# Conversión alimenticia
	feed_conversion_male = models.DecimalField(max_digits=6, decimal_places=3, null=True, blank=True, help_text="Conversión alimenticia machos")
	feed_conversion_female = models.DecimalField(max_digits=6, decimal_places=3, null=True, blank=True, help_text="Conversión alimenticia hembras")

	# Temperatura ambiente
	temperature = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
	notes = models.TextField(blank=True)

	class Meta:
		unique_together = ['flock', 'date']
		ordering = ['date']

	def __str__(self):
		return f"Registro {self.flock} - Día {self.day_number} ({self.date})"

	def save(self, *args, **kwargs):
		# Auto-calcular semana y día desde la fecha de llegada
		if self.flock and self.date:
			days_since = (self.date - self.flock.arrival_date).days
			self.day_number = days_since
			self.week_number = (days_since // 7) + 1

		# Auto-calcular consumo por pollo
		if self.balance_male > 0 and self.feed_consumed_kg_male > 0:
			self.feed_per_bird_gr_male = (self.feed_consumed_kg_male * 1000) / self.balance_male
		if self.balance_female > 0 and self.feed_consumed_kg_female > 0:
			self.feed_per_bird_gr_female = (self.feed_consumed_kg_female * 1000) / self.balance_female

		# Auto-calcular conversión alimenticia
		if self.weight_male and self.accumulated_feed_per_bird_gr_male and self.weight_male > 0:
			initial_w = float(self.flock.initial_weight_male or self.flock.initial_weight or 0)
			weight_gain = float(self.weight_male) - initial_w
			if weight_gain > 0:
				self.feed_conversion_male = float(self.accumulated_feed_per_bird_gr_male) / weight_gain

		if self.weight_female and self.accumulated_feed_per_bird_gr_female and self.weight_female > 0:
			initial_w = float(self.flock.initial_weight_female or self.flock.initial_weight or 0)
			weight_gain = float(self.weight_female) - initial_w
			if weight_gain > 0:
				self.feed_conversion_female = float(self.accumulated_feed_per_bird_gr_female) / weight_gain

		# Actualizar cantidades del lote
		if not kwargs.pop('_skip_flock_update', False):
			total_mortality = (self.mortality_male or 0) + (self.mortality_female or 0)
			total_process = (self.process_output_male or 0) + (self.process_output_female or 0)
			self.flock.current_quantity_male = self.balance_male
			self.flock.current_quantity_female = self.balance_female
			self.flock.current_quantity = self.balance_male + self.balance_female
			self.flock.save(update_fields=['current_quantity', 'current_quantity_male', 'current_quantity_female'])

		super().save(*args, **kwargs)


class DispatchRecord(SyncableRecordModel):
	"""Registro de despacho/pesas - replica la hoja PESAS del Excel"""
	flock = models.ForeignKey(Flock, on_delete=models.CASCADE, related_name='dispatch_records')

	# Info general despacho
	dispatch_date = models.DateField()
	day_number = models.PositiveIntegerField(help_text="Día de edad al despacho")
	manifest_number = models.CharField(max_length=50, help_text="Número de planilla")
	shed_name = models.CharField(max_length=50, blank=True, help_text="Galpón")

	# Cantidades despachadas
	males_count = models.PositiveIntegerField(default=0, help_text="Cantidad machos despachados")
	females_count = models.PositiveIntegerField(default=0, help_text="Cantidad hembras despachadas")
	total_birds = models.PositiveIntegerField(help_text="Total pollos despachados")

	# Peso en granja
	farm_avg_weight = models.DecimalField(max_digits=8, decimal_places=2, help_text="Peso promedio granja (kg)")
	farm_total_kg = models.DecimalField(max_digits=10, decimal_places=2, help_text="Kilos totales granja")

	# Peso en planta de proceso
	plant_birds = models.PositiveIntegerField(null=True, blank=True, help_text="Pollos recibidos planta (descontando faltantes)")
	plant_missing = models.PositiveIntegerField(default=0, help_text="Pollos faltantes en planta")
	drowned = models.PositiveIntegerField(default=0, help_text="Ahogados en transporte")
	plant_avg_weight = models.DecimalField(max_digits=8, decimal_places=4, null=True, blank=True, help_text="Peso promedio planta (kg)")
	plant_total_kg = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Kilos totales planta")
	plant_shrinkage_grams = models.DecimalField(max_digits=10, decimal_places=6, null=True, blank=True, help_text="Merma planta (gramos por pollo)")

	# Peso venta
	sale_birds = models.PositiveIntegerField(null=True, blank=True, help_text="Pollos vendidos")
	sale_discount_kg = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text="Descuento en kilos")
	sale_total_kg = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Kilos venta")
	sale_avg_weight = models.DecimalField(max_digits=8, decimal_places=6, null=True, blank=True, help_text="Peso promedio venta (kg)")
	total_shrinkage_grams = models.DecimalField(max_digits=10, decimal_places=6, null=True, blank=True, help_text="Merma total granja-venta (gramos por pollo)")

	# Observaciones
	observations = models.TextField(blank=True, help_text="Observaciones del despacho (ej: descuentos por comprador)")

	class Meta:
		ordering = ['dispatch_date']

	def __str__(self):
		return f"Despacho {self.manifest_number} - {self.flock} ({self.dispatch_date})"

	def save(self, *args, **kwargs):
		# Auto-calcular total_birds si no se proporcionó
		if not self.total_birds:
			self.total_birds = (self.males_count or 0) + (self.females_count or 0)

		# Auto-calcular day_number
		if self.flock and self.dispatch_date and not self.day_number:
			self.day_number = (self.dispatch_date - self.flock.arrival_date).days

		# Auto-calcular merma planta
		if self.farm_total_kg and self.plant_total_kg and self.plant_birds and self.plant_birds > 0:
			shrinkage_kg = float(self.farm_total_kg) - float(self.plant_total_kg)
			self.plant_shrinkage_grams = (shrinkage_kg / self.plant_birds) * 1000

		# Auto-calcular merma total
		if self.farm_total_kg and self.sale_total_kg and self.total_birds and self.total_birds > 0:
			total_shrinkage_kg = float(self.farm_total_kg) - float(self.sale_total_kg)
			self.total_shrinkage_grams = (total_shrinkage_kg / self.total_birds) * 1000

		# Auto-calcular plant_birds
		if not self.plant_birds and self.total_birds:
			self.plant_birds = self.total_birds - (self.drowned or 0) - (self.plant_missing or 0)

		# Actualizar el saldo del lote (restar pollos despachados)
		if not kwargs.pop('_skip_flock_update', False):
			if not self.pk:  # Solo en creación
				self.flock.current_quantity = max(0, self.flock.current_quantity - self.total_birds)
				self.flock.current_quantity_male = max(0, self.flock.current_quantity_male - (self.males_count or 0))
				self.flock.current_quantity_female = max(0, self.flock.current_quantity_female - (self.females_count or 0))
				self.flock.save(update_fields=['current_quantity', 'current_quantity_male', 'current_quantity_female'])

		super().save(*args, **kwargs)
