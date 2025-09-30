from django.db import models
from django.conf import settings
from django.utils import timezone

from apps.farms.models import Farm


class BaseModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class AlarmConfiguration(BaseModel):
    ALARM_TYPES = [
        ('MORTALITY', 'Mortalidad Alta'),
        ('WEIGHT', 'Peso Fuera de Rango'),
        ('WEIGHT_DEVIATION', 'Desviación de Peso'),
        ('STOCK', 'Stock Crítico'),
        ('CONSUMPTION', 'Consumo Anómalo'),
        ('NO_RECORDS', 'Sin Registros'),
    ]

    alarm_type = models.CharField(max_length=20, choices=ALARM_TYPES)
    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, related_name='alarm_configs')

    threshold_value = models.DecimalField(max_digits=8, decimal_places=2)
    critical_threshold = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)

    evaluation_period_hours = models.PositiveIntegerField(default=24)
    consecutive_occurrences = models.PositiveIntegerField(default=1)

    notify_farm_manager = models.BooleanField(default=True)
    notify_veterinarian = models.BooleanField(default=True)
    notify_galponeros = models.BooleanField(default=False)

    escalate_after_hours = models.PositiveIntegerField(null=True, blank=True)
    escalate_to_admin = models.BooleanField(default=False)
    escalation_role_name = models.CharField(max_length=100, null=True, blank=True)

    is_active = models.BooleanField(default=True)

    class Meta:
        unique_together = ['alarm_type', 'farm']

    def __str__(self):
        return f"{self.farm.name} - {self.alarm_type}"

    def get_notification_recipients(self):
        from apps.users.models import User

        recipients = []
        if self.notify_farm_manager and getattr(self.farm, 'farm_manager', None):
            recipients.append(self.farm.farm_manager)

        if self.notify_veterinarian:
            vets = User.objects.filter(role__name='Veterinario', assigned_farms=self.farm)
            recipients.extend(vets)

        if self.notify_galponeros:
            galponeros = User.objects.filter(assigned_sheds__farm=self.farm).distinct()
            recipients.extend(galponeros)

        return list({u.id: u for u in recipients}.values())


class Alarm(BaseModel):
    STATUS_CHOICES = [
        ('PENDING', 'Pendiente'),
        ('RESOLVED', 'Resuelta'),
        ('ESCALATED', 'Escalada'),
    ]

    alarm_type = models.CharField(max_length=20)
    description = models.TextField()
    priority = models.CharField(max_length=20, default='MEDIUM')

    # structured references to the source that originated the alarm (helps de-duplication)
    source_type = models.CharField(max_length=30, null=True, blank=True)  # e.g. 'mortality', 'daily_weight'
    source_date = models.DateField(null=True, blank=True)
    source_id = models.BigIntegerField(null=True, blank=True)

    farm = models.ForeignKey(Farm, null=True, blank=True, on_delete=models.CASCADE)
    flock = models.ForeignKey('flocks.Flock', null=True, blank=True, on_delete=models.CASCADE)
    shed = models.ForeignKey('farms.Shed', null=True, blank=True, on_delete=models.CASCADE)
    inventory_item = models.ForeignKey('inventory.InventoryItem', null=True, blank=True, on_delete=models.CASCADE)

    configuration = models.ForeignKey(AlarmConfiguration, null=True, blank=True, on_delete=models.SET_NULL)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')

    def __str__(self):
        return f"Alarm {self.id} - {self.alarm_type} - {self.status}"

    class Meta:
        indexes = [models.Index(fields=['source_type', 'source_date']), models.Index(fields=['farm', 'flock'])]


class AlarmEscalation(BaseModel):
    alarm = models.ForeignKey(Alarm, on_delete=models.CASCADE, related_name='escalations')
    escalated_to = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    escalation_reason = models.CharField(max_length=100)
    escalated_at = models.DateTimeField(auto_now_add=True)


class NotificationLog(BaseModel):
    alarm = models.ForeignKey(Alarm, on_delete=models.CASCADE, related_name='notification_logs')
    recipient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    notification_type = models.CharField(max_length=20, choices=[('PUSH', 'Push'), ('EMAIL', 'Email'), ('SMS', 'SMS')])
    status = models.CharField(max_length=20, choices=[('SENT', 'Sent'), ('ERROR', 'Error'), ('DELIVERED', 'Delivered')])
    error_message = models.TextField(blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

