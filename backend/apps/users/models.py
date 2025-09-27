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
