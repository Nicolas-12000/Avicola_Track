from django.contrib import admin
from .models import Report, ReportTemplate, ReportSchedule


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['name', 'report_type', 'status', 'farm', 'created_by', 'created_at']
    list_filter = ['report_type', 'status', 'farm', 'created_at']
    search_fields = ['name', 'created_by__username', 'farm__name']
    readonly_fields = ['created_at', 'updated_at', 'data', 'file_path', 'error_message']
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'report_type', 'status')
        }),
        ('Filtros', {
            'fields': ('farm', 'shed', 'flock', 'date_from', 'date_to')
        }),
        ('Configuración', {
            'fields': ('export_format', 'include_charts')
        }),
        ('Resultado', {
            'fields': ('data', 'file_path', 'error_message'),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )


@admin.register(ReportTemplate)
class ReportTemplateAdmin(admin.ModelAdmin):
    list_display = ['name', 'report_type', 'is_active', 'created_by', 'created_at']
    list_filter = ['report_type', 'is_active', 'created_at']
    search_fields = ['name', 'description', 'created_by__username']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(ReportSchedule)
class ReportScheduleAdmin(admin.ModelAdmin):
    list_display = ['name', 'template', 'frequency', 'is_active', 'last_run', 'next_run']
    list_filter = ['frequency', 'is_active', 'template__report_type']
    search_fields = ['name', 'template__name']
    readonly_fields = ['last_run', 'created_at', 'updated_at']
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'template', 'is_active')
        }),
        ('Programación', {
            'fields': ('frequency', 'day_of_week', 'day_of_month', 'hour')
        }),
        ('Filtros', {
            'fields': ('farm', 'shed')
        }),
        ('Notificaciones', {
            'fields': ('recipients',)
        }),
        ('Estado', {
            'fields': ('last_run', 'next_run'),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
