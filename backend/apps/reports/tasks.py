from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import ReportSchedule, Report, ReportStatus
from .serializers import ReportCreateSerializer
from .services import ProductivityReportService


@shared_task
def execute_scheduled_reports():
    """Ejecuta reportes programados que están listos"""
    now = timezone.now()
    
    # Obtener programaciones que deben ejecutarse
    schedules = ReportSchedule.objects.filter(
        is_active=True,
        next_run__lte=now
    ).select_related('template')
    
    executed_count = 0
    
    for schedule in schedules:
        try:
            # Determinar el período del reporte según la frecuencia
            if schedule.frequency == 'daily':
                date_from = now.date() - timedelta(days=1)
                date_to = now.date() - timedelta(days=1)
            elif schedule.frequency == 'weekly':
                date_from = now.date() - timedelta(days=7)
                date_to = now.date() - timedelta(days=1)
            elif schedule.frequency == 'monthly':
                # Mes anterior completo
                first_day_current = now.date().replace(day=1)
                date_to = first_day_current - timedelta(days=1)
                date_from = date_to.replace(day=1)
            elif schedule.frequency == 'quarterly':
                # Trimestre anterior
                quarter = (now.month - 1) // 3
                if quarter == 0:
                    # Trimestre anterior del año pasado
                    date_from = now.date().replace(year=now.year-1, month=10, day=1)
                    date_to = now.date().replace(year=now.year-1, month=12, day=31)
                else:
                    start_month = (quarter - 1) * 3 + 1
                    end_month = quarter * 3
                    date_from = now.date().replace(month=start_month, day=1)
                    date_to = now.date().replace(month=end_month, day=31)
            else:
                continue
            
            # Crear reporte
            report_data = {
                'name': f"{schedule.template.name} - Automático {now.strftime('%Y-%m-%d %H:%M')}",
                'report_type': schedule.template.report_type,
                'farm': schedule.farm.id if schedule.farm else None,
                'shed': schedule.shed.id if schedule.shed else None,
                'date_from': date_from,
                'date_to': date_to,
                'export_format': 'excel',
                'include_charts': True
            }
            
            # Crear reporte usando el primer usuario disponible como creador
            from django.contrib.auth import get_user_model
            User = get_user_model()
            creator = User.objects.filter(is_active=True).first()
            if not creator:
                continue
            
            report = Report.objects.create(
                name=report_data['name'],
                report_type=report_data['report_type'],
                farm_id=report_data['farm'],
                shed_id=report_data['shed'],
                date_from=report_data['date_from'],
                date_to=report_data['date_to'],
                export_format=report_data['export_format'],
                include_charts=report_data['include_charts'],
                created_by=creator
            )
            
            # Generar reporte en background
            generate_report_task.delay(report.id)
            
            # Actualizar programación
            schedule.last_run = now
            schedule.next_run = _calculate_next_run(schedule, now)
            schedule.save()
            
            executed_count += 1
            
        except Exception as e:
            # Log el error pero continúa con las demás programaciones
            print(f"Error ejecutando reporte programado {schedule.name}: {str(e)}")
    
    return {
        'executed_schedules': executed_count,
        'next_execution': timezone.now() + timedelta(hours=1)
    }


@shared_task
def generate_report_task(report_id):
    """Genera un reporte específico en background"""
    try:
        report = Report.objects.get(id=report_id)
        
        if report.report_type == 'productivity':
            service = ProductivityReportService(report)
            service.generate_report()
        else:
            report.set_failed(f'Tipo de reporte {report.report_type} no implementado')
        
        return {'report_id': report_id, 'status': 'completed'}
        
    except Report.DoesNotExist:
        return {'error': f'Reporte {report_id} no encontrado'}
    except Exception as e:
        try:
            report = Report.objects.get(id=report_id)
            report.set_failed(str(e))
        except:
            pass
        return {'error': str(e)}


@shared_task
def cleanup_old_reports():
    """Limpia reportes antiguos y archivos asociados"""
    import os
    
    # Eliminar reportes completados más antiguos de 90 días
    cutoff_date = timezone.now() - timedelta(days=90)
    old_reports = Report.objects.filter(
        status=ReportStatus.COMPLETED,
        created_at__lt=cutoff_date
    )
    
    deleted_files = 0
    for report in old_reports:
        if report.file_path and os.path.exists(report.file_path):
            try:
                os.remove(report.file_path)
                deleted_files += 1
            except OSError:
                pass
    
    deleted_reports = old_reports.count()
    old_reports.delete()
    
    # Eliminar reportes fallidos más antiguos de 30 días
    failed_cutoff = timezone.now() - timedelta(days=30)
    failed_reports = Report.objects.filter(
        status=ReportStatus.FAILED,
        created_at__lt=failed_cutoff
    )
    deleted_failed = failed_reports.count()
    failed_reports.delete()
    
    return {
        'deleted_reports': deleted_reports,
        'deleted_failed_reports': deleted_failed,
        'deleted_files': deleted_files
    }


def _calculate_next_run(schedule, from_time):
    """Calcula la próxima fecha de ejecución"""
    next_run = from_time.replace(hour=schedule.hour, minute=0, second=0, microsecond=0)
    
    if schedule.frequency == 'daily':
        next_run += timedelta(days=1)
    elif schedule.frequency == 'weekly':
        days_ahead = schedule.day_of_week - next_run.weekday()
        if days_ahead <= 0:
            days_ahead += 7
        next_run += timedelta(days=days_ahead)
    elif schedule.frequency == 'monthly':
        # Próximo mes en el día especificado
        if next_run.month == 12:
            next_run = next_run.replace(year=next_run.year + 1, month=1, day=schedule.day_of_month)
        else:
            next_run = next_run.replace(month=next_run.month + 1, day=schedule.day_of_month)
    elif schedule.frequency == 'quarterly':
        # Próximo trimestre
        next_run += timedelta(days=90)  # Aproximado
    
    return next_run


@shared_task
def send_report_notifications(report_id):
    """Envía notificaciones cuando un reporte está listo"""
    try:
        report = Report.objects.get(id=report_id)
        
        if report.status != ReportStatus.COMPLETED:
            return {'error': 'Reporte no completado'}
        
        # Buscar programaciones asociadas para obtener destinatarios
        schedules = ReportSchedule.objects.filter(
            template__report_type=report.report_type,
            farm=report.farm,
            is_active=True
        )
        
        notification_count = 0
        
        for schedule in schedules:
            if schedule.recipients:
                # Aquí se implementaría el envío de emails
                # Por ahora solo contamos las notificaciones que se enviarían
                notification_count += len(schedule.recipients)
        
        return {
            'report_id': report_id,
            'notifications_sent': notification_count
        }
        
    except Report.DoesNotExist:
        return {'error': f'Reporte {report_id} no encontrado'}
    except Exception as e:
        return {'error': str(e)}