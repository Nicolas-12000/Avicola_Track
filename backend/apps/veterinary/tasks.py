from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from apps.alarms.notifications import AlarmNotificationService
from apps.alarms.models import NotificationLog
from .models import VeterinaryVisit


@shared_task
def send_visit_reminders():
    """
    Task ejecutada periódicamente para enviar recordatorios de visitas veterinarias.
    Envía notificaciones 24 horas antes de la visita programada.
    """
    now = timezone.now()
    
    # Ventana de notificación: visitas en las próximas 24-25 horas
    start_time = now + timedelta(hours=23, minutes=50)
    end_time = now + timedelta(hours=25)
    
    # Filtrar visitas programadas en la ventana de tiempo
    upcoming_visits = VeterinaryVisit.objects.filter(
        status='scheduled',
        visit_date__gte=start_time,
        visit_date__lte=end_time
    ).select_related('farm', 'veterinarian').prefetch_related('flocks')
    
    notification_service = AlarmNotificationService()
    sent_count = 0
    
    for visit in upcoming_visits:
        # Verificar si ya se envió recordatorio para esta visita
        existing_notification = NotificationLog.objects.filter(
            notification_type='REMINDER',
            related_entity_type='veterinary_visit',
            related_entity_id=visit.id,
            created_at__gte=now - timedelta(hours=26)  # Evitar duplicados en últimas 26h
        ).exists()
        
        if existing_notification:
            continue
        
        # Preparar mensaje de recordatorio
        time_until = visit.visit_date - now
        hours_until = int(time_until.total_seconds() / 3600)
        
        message_parts = [
            f"Recordatorio: Visita veterinaria programada en {hours_until} horas",
            f"📅 Fecha: {visit.visit_date.strftime('%d/%m/%Y %H:%M')}",
            f"🏠 Granja: {visit.farm.name if visit.farm else 'N/A'}",
        ]
        
        if visit.expected_duration_days > 1:
            message_parts.append(f"⏱️ Duración: {visit.expected_duration_days} días")
        
        if visit.visit_type:
            type_labels = {
                'routine': 'Rutina',
                'emergency': 'Emergencia',
                'vaccination': 'Vacunación',
                'treatment': 'Tratamiento',
            }
            message_parts.append(f"📋 Tipo: {type_labels.get(visit.visit_type, visit.visit_type)}")
        
        flocks = visit.flocks.all()
        if flocks:
            flock_names = ', '.join([f"Lote {f.id}" for f in flocks[:3]])
            if len(flocks) > 3:
                flock_names += f" y {len(flocks) - 3} más"
            message_parts.append(f"🐔 Lotes: {flock_names}")
        
        if visit.reason:
            message_parts.append(f"📝 Motivo: {visit.reason[:100]}")
        
        message = '\n'.join(message_parts)
        
        # Enviar notificación al veterinario
        if visit.veterinarian:
            try:
                notification_service.send_notification(
                    user=visit.veterinarian,
                    message=message,
                    notification_type='REMINDER',
                    priority='medium',
                    related_entity_type='veterinary_visit',
                    related_entity_id=visit.id
                )
                sent_count += 1
            except Exception as e:
                print(f"Error enviando recordatorio para visita {visit.id}: {str(e)}")
        
        # Enviar notificación al admin de granja si existe
        if visit.farm and hasattr(visit.farm, 'admin'):
            try:
                notification_service.send_notification(
                    user=visit.farm.admin,
                    message=message,
                    notification_type='REMINDER',
                    priority='medium',
                    related_entity_type='veterinary_visit',
                    related_entity_id=visit.id
                )
            except Exception as e:
                print(f"Error enviando recordatorio al admin de granja {visit.farm.id}: {str(e)}")
    
    return f"Recordatorios enviados: {sent_count} visitas"


@shared_task
def check_overdue_visits():
    """
    Task para verificar visitas que no se han completado después de la fecha programada.
    Envía notificaciones de seguimiento.
    """
    now = timezone.now()
    
    # Visitas programadas que deberían haber terminado hace más de 1 hora
    overdue_visits = VeterinaryVisit.objects.filter(
        status='scheduled',
        visit_date__lt=now - timedelta(hours=1)
    ).select_related('farm', 'veterinarian')
    
    notification_service = AlarmNotificationService()
    notified_count = 0
    
    for visit in overdue_visits:
        # Verificar que no se haya enviado notificación de seguimiento reciente
        existing_notification = NotificationLog.objects.filter(
            notification_type='ALERT',
            related_entity_type='veterinary_visit_overdue',
            related_entity_id=visit.id,
            created_at__gte=now - timedelta(hours=12)
        ).exists()
        
        if existing_notification:
            continue
        
        message = (
            f"⚠️ Visita veterinaria pendiente de actualización\n"
            f"📅 Programada: {visit.visit_date.strftime('%d/%m/%Y %H:%M')}\n"
            f"🏠 Granja: {visit.farm.name if visit.farm else 'N/A'}\n"
            f"Por favor actualice el estado de la visita."
        )
        
        # Notificar al veterinario
        if visit.veterinarian:
            try:
                notification_service.send_notification(
                    user=visit.veterinarian,
                    message=message,
                    notification_type='ALERT',
                    priority='high',
                    related_entity_type='veterinary_visit_overdue',
                    related_entity_id=visit.id
                )
                notified_count += 1
            except Exception as e:
                print(f"Error enviando alerta de visita vencida {visit.id}: {str(e)}")
    
    return f"Alertas de visitas vencidas enviadas: {notified_count}"


@shared_task
def send_daily_schedule_summary():
    """
    Envía un resumen diario de las visitas programadas a cada veterinario.
    Se ejecuta cada mañana a las 7:00 AM.
    """
    now = timezone.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_end = today_start + timedelta(days=1)
    
    # Obtener todas las visitas programadas para hoy
    today_visits = VeterinaryVisit.objects.filter(
        status='scheduled',
        visit_date__gte=today_start,
        visit_date__lt=today_end
    ).select_related('farm', 'veterinarian').prefetch_related('flocks').order_by('visit_date')
    
    # Agrupar por veterinario
    visits_by_vet = {}
    for visit in today_visits:
        if visit.veterinarian:
            vet_id = visit.veterinarian.id
            if vet_id not in visits_by_vet:
                visits_by_vet[vet_id] = []
            visits_by_vet[vet_id].append(visit)
    
    notification_service = AlarmNotificationService()
    summaries_sent = 0
    
    for vet_id, visits in visits_by_vet.items():
        veterinarian = visits[0].veterinarian
        
        message_parts = [
            f"📋 Agenda del día - {now.strftime('%d/%m/%Y')}",
            f"Tiene {len(visits)} visita(s) programada(s):\n"
        ]
        
        for i, visit in enumerate(visits, 1):
            visit_info = [
                f"{i}. {visit.visit_date.strftime('%H:%M')} - {visit.farm.name if visit.farm else 'N/A'}"
            ]
            
            if visit.visit_type:
                type_labels = {
                    'routine': 'Rutina',
                    'emergency': 'Emergencia',
                    'vaccination': 'Vacunación',
                    'treatment': 'Tratamiento',
                }
                visit_info.append(f"   Tipo: {type_labels.get(visit.visit_type, visit.visit_type)}")
            
            if visit.expected_duration_days > 1:
                visit_info.append(f"   Duración: {visit.expected_duration_days} días")
            
            flocks = visit.flocks.all()
            if flocks:
                visit_info.append(f"   Lotes a revisar: {len(flocks)}")
            
            message_parts.append('\n'.join(visit_info))
        
        message = '\n'.join(message_parts)
        
        try:
            notification_service.send_notification(
                user=veterinarian,
                message=message,
                notification_type='INFO',
                priority='low',
                related_entity_type='daily_schedule',
                related_entity_id=now.date().toordinal()
            )
            summaries_sent += 1
        except Exception as e:
            print(f"Error enviando resumen diario a veterinario {vet_id}: {str(e)}")
    
    return f"Resúmenes diarios enviados: {summaries_sent} veterinarios"
