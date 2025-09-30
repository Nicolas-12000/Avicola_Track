from django.utils import timezone
from django.db import transaction
import logging

from .models import SyncConflict

logger = logging.getLogger(__name__)


class ConflictResolutionService:
    """Servicio para crear y resolver conflictos de sincronización"""

    @staticmethod
    def _analyze_conflict(server_record, client_data):
        """Analiza datos y retorna tipo de conflicto y prioridad sugerida"""
        # Default
        conflict_type = 'DATA_MISMATCH'
        priority = 'MEDIUM'

        if not server_record:
            return {'type': 'DUPLICATE', 'priority': 'LOW'}

        # Timestamp difference
        server_ts = getattr(server_record, 'created_at', None)
        client_ts = None
        try:
            client_ts = timezone.datetime.fromisoformat(client_data.get('timestamp')) if client_data.get('timestamp') else None
        except Exception:
            client_ts = None

        if server_ts and client_ts:
            diff = abs((server_ts - client_ts).total_seconds())
            if diff > 3600:
                return {'type': 'TIMESTAMP_DIFF', 'priority': 'HIGH'}

        # Specific heuristics for weight records
        if client_data.get('type') == 'weight' and hasattr(server_record, 'average_weight'):
            try:
                server_w = float(getattr(server_record, 'average_weight'))
                client_w = float(client_data.get('data', {}).get('average_weight', server_w))
                if abs(server_w - client_w) > 100:
                    return {'type': 'DATA_MISMATCH', 'priority': 'HIGH'}
            except Exception:
                pass

        return {'type': conflict_type, 'priority': priority}

    @staticmethod
    def create_conflict(record_type, server_record, client_data, user, device_id, farm=None):
        """Crea un conflicto para resolución manual y notifica al administrador de la granja"""
        analysis = ConflictResolutionService._analyze_conflict(server_record, client_data)

        conflict = SyncConflict.objects.create(
            conflict_type=analysis.get('type', 'DATA_MISMATCH'),
            record_type=record_type,
            farm=farm,
            server_data={'id': getattr(server_record, 'id', None), 'data': ConflictResolutionService._serialize_record(server_record)},
            client_data=client_data,
            device_info={'device_id': device_id, 'user': user.username, 'timestamp': timezone.now().isoformat()},
            reported_by=user,
            priority=analysis.get('priority', 'MEDIUM')
        )

        # Notify farm manager (if available) using alarms notification adapters
        try:
            if farm and getattr(farm, 'farm_manager', None):
                from apps.alarms.notifications import get_default_adapter
                from apps.alarms.models import Alarm

                adapter = get_default_adapter()
                manager = farm.farm_manager
                # create a lightweight Alarm so adapters that log notifications have an Alarm to link
                alarm = Alarm.objects.create(
                    alarm_type=(conflict.record_type or 'SYNC').upper(),
                    description=f'Conflicto sync {conflict.record_type} ({conflict.conflict_type})',
                    priority=conflict.priority or 'MEDIUM',
                    farm=farm,
                    flock=None,
                )
                payload = {
                    'title': f'Conflicto de sync: {conflict.record_type}',
                    'body': f'Tipo: {conflict.conflict_type} - Prioridad: {conflict.priority}'
                }
                adapter.send(alarm, manager, payload=payload)
        except Exception:
            logger.exception('Failed notifying farm manager for conflict %s', conflict.id)

        return conflict

    @staticmethod
    def resolve_conflict(conflict: SyncConflict, resolution_type: str, resolution_data: dict, resolved_by):
        """Resuelve un conflicto aplicando la solución elegida"""
        with transaction.atomic():
            if resolution_type == 'server':
                result = ConflictResolutionService._apply_server_resolution(conflict)
            elif resolution_type == 'client':
                result = ConflictResolutionService._apply_client_resolution(conflict)
            elif resolution_type == 'manual':
                result = ConflictResolutionService._apply_manual_resolution(conflict, resolution_data)
            elif resolution_type == 'ignore':
                result = {'action': 'ignored', 'message': 'Conflicto ignorado'}
            else:
                raise ValueError('Unknown resolution_type')

            conflict.resolution_status = f'RESOLVED_{resolution_type.upper()}'
            conflict.resolved_by = resolved_by
            conflict.resolved_at = timezone.now()
            conflict.resolution_data = result
            conflict.resolution_notes = resolution_data.get('notes', '') if isinstance(resolution_data, dict) else ''
            conflict.save()

        # Optionally notify reporter and farm manager about resolution
        try:
            from apps.alarms.notifications import get_default_adapter
            from apps.alarms.models import Alarm

            adapter = get_default_adapter()
            # create a lightweight Alarm representing the resolution notification
            alarm = Alarm.objects.create(
                alarm_type=(conflict.record_type or 'SYNC').upper(),
                description=f'Conflicto {conflict.id} resuelto: {result.get("action", "resolved")}',
                priority=conflict.priority or 'MEDIUM',
                farm=conflict.farm,
                flock=getattr(conflict, 'flock', None),
            )

            if conflict.reported_by:
                adapter.send(alarm, conflict.reported_by, payload={'title': 'Conflicto resuelto', 'body': str(result)})
            if conflict.farm and getattr(conflict.farm, 'farm_manager', None):
                adapter.send(alarm, conflict.farm.farm_manager, payload={'title': 'Conflicto resuelto', 'body': str(result)})
        except Exception:
            logger.exception('Failed to send resolution notifications for conflict %s', conflict.id)

        return result

    @staticmethod
    def _apply_server_resolution(conflict: SyncConflict):
        # Server wins: no-op besides logging
        return {'action': 'kept_server', 'message': 'Datos del servidor conservados'}

    @staticmethod
    def _apply_client_resolution(conflict: SyncConflict):
        # Client wins: try to apply client data depending on record_type
        rt = conflict.record_type
        if rt == 'mortality':
            return ConflictResolutionService._apply_mortality_client(conflict)

        # Generic fallback: record intent only
        return {'action': 'applied_client', 'message': 'Se aplicaron datos del cliente', 'client_data': conflict.client_data}

    @staticmethod
    def _apply_mortality_client(conflict: SyncConflict):
        """Apply client mortality data: expects client_data to include flock_id, date, deaths, cause_name(optional)"""
        from django.core.exceptions import ValidationError
        from apps.flocks.models import MortalityRecord, MortalityCause, Flock

        data = conflict.client_data
        flock_id = data.get('flock_id') or (conflict.server_data.get('data', {}) or {}).get('flock_id')
        if not flock_id:
            raise ValidationError('flock_id requerido en client_data')

        flock = Flock.objects.select_for_update().get(id=flock_id)

        deaths = int(data.get('deaths', 0))
        date_str = data.get('date')
        try:
            date = timezone.datetime.fromisoformat(date_str).date() if date_str else timezone.now().date()
        except Exception:
            date = timezone.now().date()

        # Validation: deaths must not exceed current_quantity
        if deaths > flock.current_quantity:
            raise ValidationError(f'Mortalidad ({deaths}) excede cantidad actual del lote ({flock.current_quantity})')

        cause = None
        if data.get('cause_name'):
            cause, _ = MortalityCause.objects.get_or_create(name=data.get('cause_name'), defaults={'category': 'OTHER'})

        # Try to find existing record for the date
        mr, created = MortalityRecord.objects.get_or_create(
            flock=flock,
            date=date,
            defaults={'deaths': deaths, 'cause': cause, 'recorded_by': conflict.reported_by}
        )

        if not created:
            # sum deaths
            total = mr.deaths + deaths
            if total > (flock.current_quantity + mr.deaths):
                raise ValidationError('La mortalidad total excede la cantidad del lote')
            mr.deaths = total
            mr.save()
        else:
            mr.save()

        # Update flock current_quantity already handled in MortalityRecord.save()

        return {'action': 'applied_client', 'message': 'Mortalidad aplicada', 'mortality_record_id': mr.id, 'created': created}

    @staticmethod
    def _apply_manual_resolution(conflict: SyncConflict, resolution_data: dict):
        # Manual resolution: expect resolution_data to include final data applied
        return {'action': 'manual', 'message': 'Se aplicaron datos manuales', 'data': resolution_data}

    @staticmethod
    def _serialize_record(rec):
        if rec is None:
            return None
        # Try common fields
        try:
            return {
                'id': getattr(rec, 'id', None),
                'created_at': getattr(rec, 'created_at', None).isoformat() if getattr(rec, 'created_at', None) else None
            }
        except Exception:
            return {}

