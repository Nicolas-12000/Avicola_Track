from django.db import models
from django.utils import timezone
from django.conf import settings
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock
import json


class ReportType(models.TextChoices):
    PRODUCTIVITY = 'productivity', 'Reporte de Productividad'
    MORTALITY = 'mortality', 'Reporte de Mortalidad'
    WEIGHT = 'weight', 'Reporte de Peso'
    CONSUMPTION = 'consumption', 'Reporte de Consumo'
    INVENTORY = 'inventory', 'Reporte de Inventario'
    ALARMS = 'alarms', 'Reporte de Alarmas'
    FINANCIAL = 'financial', 'Reporte Financiero'


class ReportStatus(models.TextChoices):
    PENDING = 'pending', 'Pendiente'
    PROCESSING = 'processing', 'Procesando'
    COMPLETED = 'completed', 'Completado'
    FAILED = 'failed', 'Fallido'


class Report(models.Model):
    """Modelo para gestionar reportes generados"""
    
    name = models.CharField(max_length=200)
    report_type = models.CharField(
        max_length=20,
        choices=ReportType.choices
    )
    status = models.CharField(
        max_length=20,
        choices=ReportStatus.choices,
        default=ReportStatus.PENDING
    )
    
    # Filtros del reporte
    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, null=True, blank=True)
    shed = models.ForeignKey(Shed, on_delete=models.CASCADE, null=True, blank=True)
    flock = models.ForeignKey(Flock, on_delete=models.CASCADE, null=True, blank=True)
    date_from = models.DateField()
    date_to = models.DateField()
    
    # Metadatos
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Resultado del reporte
    data = models.JSONField(default=dict, blank=True)
    file_path = models.CharField(max_length=500, blank=True, null=True)
    error_message = models.TextField(blank=True, null=True)
    
    # Configuración de exportación
    export_format = models.CharField(
        max_length=10,
        choices=[('excel', 'Excel'), ('pdf', 'PDF'), ('csv', 'CSV')],
        default='excel'
    )
    include_charts = models.BooleanField(default=True)
    
    class Meta:
        app_label = 'reports'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['report_type', 'status']),
            models.Index(fields=['farm', 'date_from', 'date_to']),
            models.Index(fields=['created_by', 'created_at']),
        ]
    
    def __str__(self):
        return f"{self.get_report_type_display()} - {self.name}"
    
    @property
    def duration_days(self):
        return (self.date_to - self.date_from).days + 1
    
    def set_processing(self):
        self.status = ReportStatus.PROCESSING
        self.save(update_fields=['status', 'updated_at'])
    
    def set_completed(self, data=None, file_path=None):
        self.status = ReportStatus.COMPLETED
        if data:
            self.data = data
        if file_path:
            self.file_path = file_path
        self.save(update_fields=['status', 'data', 'file_path', 'updated_at'])
    
    def set_failed(self, error_message):
        self.status = ReportStatus.FAILED
        self.error_message = error_message
        self.save(update_fields=['status', 'error_message', 'updated_at'])


class ReportTemplate(models.Model):
    """Plantillas predefinidas de reportes"""
    
    name = models.CharField(max_length=200)
    report_type = models.CharField(
        max_length=20,
        choices=ReportType.choices
    )
    description = models.TextField()
    configuration = models.JSONField(default=dict)
    is_active = models.BooleanField(default=True)
    
    # Metadatos
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        app_label = 'reports'
        unique_together = ['name', 'report_type']
        ordering = ['report_type', 'name']
    
    def __str__(self):
        return f"{self.get_report_type_display()} - {self.name}"


class ReportSchedule(models.Model):
    """Programación automática de reportes"""
    
    name = models.CharField(max_length=200)
    template = models.ForeignKey(ReportTemplate, on_delete=models.CASCADE)
    
    # Configuración de programación
    frequency = models.CharField(
        max_length=20,
        choices=[
            ('daily', 'Diario'),
            ('weekly', 'Semanal'),
            ('monthly', 'Mensual'),
            ('quarterly', 'Trimestral')
        ]
    )
    day_of_week = models.IntegerField(null=True, blank=True)  # Para frecuencia semanal
    day_of_month = models.IntegerField(null=True, blank=True)  # Para frecuencia mensual
    hour = models.IntegerField(default=8)  # Hora de ejecución
    
    # Filtros aplicados automáticamente
    farm = models.ForeignKey(Farm, on_delete=models.CASCADE, null=True, blank=True)
    shed = models.ForeignKey(Shed, on_delete=models.CASCADE, null=True, blank=True)
    
    # Estado
    is_active = models.BooleanField(default=True)
    last_run = models.DateTimeField(null=True, blank=True)
    next_run = models.DateTimeField()
    
    # Destinatarios
    recipients = models.JSONField(default=list)  # Lista de emails
    
    # Metadatos
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        app_label = 'reports'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.name} - {self.get_frequency_display()}"
