from django.db import models
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from users.models import User


class Farm(models.Model):
    name = models.CharField(max_length=100, unique=True)
    location = models.CharField(max_length=200)
    responsible = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        limit_choices_to={'role__in': ['ADMIN', 'VETERINARIAN']}
    )
    status = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def clean(self):
        if not self.responsible:
            return
        if self.responsible.role not in ['ADMIN', 'VETERINARIAN']:
            raise ValidationError({'responsible': 'El responsable debe ser Administrador o Veterinario.'})

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class House(models.Model):
    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='houses')
    name = models.CharField(max_length=100)
    capacity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    current_capacity = models.PositiveIntegerField(default=0)
    responsible = models.ForeignKey(
        User,
        on_delete=models.PROTECT,
        limit_choices_to={'role': 'HOUSEMAN'}
    )
    status = models.BooleanField(default=True)

    def clean(self):
        if not self.responsible:
            return
        if self.responsible.role != 'HOUSEMAN':
            raise ValidationError({'responsible': 'El responsable debe ser un Galponero (HOUSEMAN).'})
        if self.current_capacity > self.capacity:
            raise ValidationError({'current_capacity': 'La capacidad actual no puede ser mayor que la capacidad máxima.'})

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - {self.farm.name}"
