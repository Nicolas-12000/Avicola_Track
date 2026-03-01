from django.db import models
from django.contrib.auth.models import AbstractUser


class Permission(models.Model):
	codename = models.CharField(max_length=50, unique=True)
	name = models.CharField(max_length=100)

	def __str__(self):
		return self.codename


class Role(models.Model):
	name = models.CharField(max_length=100, unique=True)
	permissions = models.ManyToManyField(Permission, blank=True)

	def __str__(self):
		return self.name


class User(AbstractUser):
	identification = models.CharField(max_length=20, unique=True)
	role = models.ForeignKey(Role, null=True, blank=True, on_delete=models.SET_NULL)
	phone = models.CharField(max_length=15, blank=True)
	is_active = models.BooleanField(default=True)

	def __str__(self):
		return f"{self.username} - {self.role.name if self.role else 'Sin rol'}"


class AuditLog(models.Model):
	"""Registro de auditoría simple para cambios en modelos críticos.
	Guarda una instantánea (o cambios) del objeto junto al actor y acción.
	"""
	ACTION_CHOICES = [
		('created', 'Creado'),
		('updated', 'Actualizado'),
		('deleted', 'Eliminado'),
	]

	from django.conf import settings
	actor = models.ForeignKey(
		settings.AUTH_USER_MODEL,
		on_delete=models.SET_NULL,
		null=True,
		blank=True,
		related_name='audit_logs'
	)
	content_type = models.CharField(max_length=200)
	object_id = models.CharField(max_length=200, null=True, blank=True)
	object_repr = models.CharField(max_length=500, null=True, blank=True)
	action = models.CharField(max_length=20, choices=ACTION_CHOICES)
	changes = models.JSONField(default=dict, blank=True)
	timestamp = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-timestamp']

	def __str__(self):
		return f"{self.get_action_display()} {self.content_type} ({self.object_id}) by {self.actor} at {self.timestamp}"
