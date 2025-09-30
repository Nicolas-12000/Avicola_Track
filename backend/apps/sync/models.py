from django.db import models
from django.utils import timezone

from apps.farms.models import Farm
from apps.users.models import User


class SyncConflict(models.Model):
	"""Conflictos de sincronización para resolución manual"""
	CONFLICT_TYPES = [
		('DUPLICATE', 'Registro Duplicado'),
		('TIMESTAMP_DIFF', 'Diferencia de Tiempo'),
		('DATA_MISMATCH', 'Datos Inconsistentes'),
		('PERMISSION', 'Conflicto de Permisos'),
		('VALIDATION', 'Error de Validación'),
	]

	RESOLUTION_STATUS = [
		('PENDING', 'Pendiente'),
		('RESOLVED_SERVER', 'Resuelto - Mantener Servidor'),
		('RESOLVED_CLIENT', 'Resuelto - Usar Cliente'),
		('RESOLVED_MANUAL', 'Resuelto - Datos Manuales'),
		('IGNORED', 'Ignorado'),
	]

	conflict_type = models.CharField(max_length=20, choices=CONFLICT_TYPES)
	record_type = models.CharField(max_length=50)
	farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='sync_conflicts')

	# Datos del conflicto
	server_data = models.JSONField()
	client_data = models.JSONField()
	device_info = models.JSONField()

	# Resolución
	resolution_status = models.CharField(max_length=20, choices=RESOLUTION_STATUS, default='PENDING')
	resolved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='resolved_sync_conflicts')
	resolved_at = models.DateTimeField(null=True, blank=True)
	resolution_data = models.JSONField(null=True, blank=True)
	resolution_notes = models.TextField(blank=True)

	# Metadatos
	reported_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reported_sync_conflicts')
	priority = models.CharField(max_length=10, choices=[
		('LOW', 'Baja'),
		('MEDIUM', 'Media'),
		('HIGH', 'Alta'),
	], default='MEDIUM')

	created_at = models.DateTimeField(default=timezone.now)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		ordering = ['-created_at']

	def __str__(self):
		return f"SyncConflict({self.record_type}, {self.conflict_type}, farm={self.farm_id})"
