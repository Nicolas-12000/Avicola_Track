from django.core.management.base import BaseCommand
from apps.reports.models import ReportTemplate, ReportType
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Crea plantillas de reportes por defecto'

    def handle(self, *args, **options):
        # Obtener el primer usuario administrador
        admin_user = User.objects.filter(is_superuser=True).first()
        if not admin_user:
            admin_user = User.objects.filter(is_staff=True).first()
        
        if not admin_user:
            self.stdout.write(
                self.style.ERROR('No se encontró ningún usuario administrador para crear las plantillas')
            )
            return

        templates = [
            {
                'name': 'Reporte Semanal de Productividad',
                'report_type': 'productivity',
                'description': 'Análisis semanal completo de productividad incluyendo peso, mortalidad, consumo y conversión alimenticia',
                'configuration': {
                    'include_weight': True,
                    'include_mortality': True,
                    'include_consumption': True,
                    'include_conversion': True,
                    'compare_with_standards': True,
                    'export_format': 'excel',
                    'include_charts': True
                }
            },
            {
                'name': 'Reporte Mensual de Mortalidad',
                'report_type': 'mortality',
                'description': 'Análisis detallado mensual de mortalidad por causas y tendencias',
                'configuration': {
                    'group_by_cause': True,
                    'include_trends': True,
                    'compare_previous_period': True,
                    'export_format': 'excel'
                }
            },
            {
                'name': 'Reporte de Evolución de Peso',
                'report_type': 'weight',
                'description': 'Seguimiento detallado de la evolución de peso y comparación con estándares de raza',
                'configuration': {
                    'compare_breed_standards': True,
                    'include_daily_gain': True,
                    'group_by_flock': True,
                    'export_format': 'excel',
                    'include_charts': True
                }
            },
            {
                'name': 'Reporte de Consumo y Conversión',
                'report_type': 'consumption',
                'description': 'Análisis de consumo de alimento y eficiencia de conversión alimenticia',
                'configuration': {
                    'calculate_conversion': True,
                    'group_by_food_type': True,
                    'include_efficiency_metrics': True,
                    'export_format': 'excel'
                }
            },
            {
                'name': 'Reporte de Estado de Inventario',
                'report_type': 'inventory',
                'description': 'Estado actual de inventario, proyecciones de stock y alertas',
                'configuration': {
                    'include_projections': True,
                    'show_critical_items': True,
                    'group_by_category': True,
                    'export_format': 'excel'
                }
            },
            {
                'name': 'Reporte de Alarmas y Resolución',
                'report_type': 'alarms',
                'description': 'Reporte de alarmas generadas, tiempos de resolución y análisis de problemas',
                'configuration': {
                    'group_by_type': True,
                    'include_resolution_time': True,
                    'show_pending_alarms': True,
                    'export_format': 'excel'
                }
            }
        ]

        created_count = 0
        
        for template_data in templates:
            template, created = ReportTemplate.objects.get_or_create(
                name=template_data['name'],
                report_type=template_data['report_type'],
                defaults={
                    'description': template_data['description'],
                    'configuration': template_data['configuration'],
                    'created_by': admin_user,
                    'is_active': True
                }
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Creada plantilla: {template.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Plantilla ya existe: {template.name}')
                )

        self.stdout.write(
            self.style.SUCCESS(f'Proceso completado. {created_count} plantillas creadas.')
        )