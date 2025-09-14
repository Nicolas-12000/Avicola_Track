from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError


class User(AbstractUser):
	ROLE_CHOICES = (
		('ADMIN', 'Administrador'),
		('VETERINARIAN', 'Veterinario'),
		('HOUSEMAN', 'Galponero'),
	)

	role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='HOUSEMAN')
	phone = models.CharField(max_length=15, blank=True)
	is_active = models.BooleanField(default=True)

	def clean(self):
		super().clean()
		# Add extra validations here if needed
		if self.phone and not self.phone.replace('+', '').replace('-', '').isdigit():
			raise ValidationError({'phone': 'El teléfono debe contener solo dígitos, + o -.'})

	def save(self, *args, **kwargs):
		self.full_clean()
		return super().save(*args, **kwargs)

	def __str__(self):
		return f"{self.username} - {self.get_role_display()}"
