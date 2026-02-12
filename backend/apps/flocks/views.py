from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from .models import Flock
from .serializers import FlockSerializer
from .permissions import IsAssignedShedWorkerOrFarmAdmin
from .mixins import RoleFilteredMixin
from django.utils import timezone
from apps.alarms.models import Alarm
from apps.alarms.services import AlarmNotificationService


class FlockViewSet(RoleFilteredMixin, viewsets.ModelViewSet):
    queryset = Flock.objects.all()
    serializer_class = FlockSerializer
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]
    role_flock_path = 'shed'  # Flock -> shed directamente

    def get_queryset(self):
        qs = Flock.objects.all()

        farm_param = self.request.query_params.get('farm')
        shed_param = self.request.query_params.get('shed')
        status_param = self.request.query_params.get('status')

        if farm_param:
            try:
                farm_id = int(farm_param)
                qs = qs.filter(shed__farm_id=farm_id)
            except (TypeError, ValueError):
                return Flock.objects.none()

        if shed_param:
            try:
                shed_id = int(shed_param)
                qs = qs.filter(shed_id=shed_id)
            except (TypeError, ValueError):
                return Flock.objects.none()

        if status_param:
            qs = qs.filter(status__iexact=status_param)

        return self.apply_role_filter(qs)

    @action(detail=True, methods=['post'], url_path='mark-inactive')
    def mark_inactive(self, request, pk=None):
        """Marcar un lote como inactivo y notificar a las partes interesadas.

        Permisos: solo `IsAssignedShedWorkerOrFarmAdmin` (ya aplicado a la vista).
        """
        flock = self.get_object()
        # verificar permisos de objeto
        self.check_object_permissions(request, flock)

        if flock.status == 'INACTIVE':
            return Response({'detail': 'Lote ya está inactivo'}, status=status.HTTP_200_OK)

        flock.status = 'INACTIVE'
        flock.save(update_fields=['status'])

        # Crear una alarma/registro de notificación
        try:
            alarm = Alarm.objects.create(
                alarm_type='FLOCK_INACTIVITY',
                description=f'Lote marcado como inactivo: {str(flock)}',
                priority='LOW',
                farm=getattr(flock.shed, 'farm', None),
                flock=flock,
                shed=flock.shed,
                source_type='flock',
                source_date=timezone.now().date(),
                source_id=flock.id,
            )
        except Exception:
            alarm = None

        # Recipientes: administrador de granja y galponero asignado
        recipients = []
        farm = getattr(flock.shed, 'farm', None)
        if farm and getattr(farm, 'farm_manager', None):
            recipients.append(farm.farm_manager)

        if getattr(flock.shed, 'assigned_worker', None):
            recipients.append(flock.shed.assigned_worker)

        # Evitar duplicados
        unique_recipients = []
        seen = set()
        for r in recipients:
            if not r:
                continue
            if r.id in seen:
                continue
            seen.add(r.id)
            unique_recipients.append(r)

        # Enviar notificaciones directamente usando el servicio existente
        sent = 0
        if alarm:
            for r in unique_recipients:
                try:
                    AlarmNotificationService.send_direct_notification(alarm, r)
                    sent += 1
                except Exception:
                    pass

        return Response({'detail': 'Lote marcado como inactivo', 'notifications_sent': sent}, status=status.HTTP_200_OK)
from django.shortcuts import render

# Create your views here.

from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile

from .models import BreedReference
from .serializers import BreedReferenceSerializer, ReferenceImportLogSerializer
from .permissions import IsAssignedShedWorkerOrFarmAdmin
from .services import BreedReferenceService


class BreedReferenceViewSet(viewsets.ModelViewSet):
    queryset = BreedReference.objects.all()
    serializer_class = BreedReferenceSerializer
    permission_classes = [IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]

    def perform_create(self, serializer):
        user = self.request.user
        with transaction.atomic():
            breed = serializer.validated_data['breed']
            age_days = serializer.validated_data['age_days']
            # deactivate previous active versions for same breed+age
            BreedReference.objects.filter(breed=breed, age_days=age_days, is_active=True).update(is_active=False)

            last = BreedReference.objects.filter(breed=breed, age_days=age_days).order_by('-version').first()
            new_version = 1 if not last else last.version + 1

            serializer.save(created_by=user, version=new_version, is_active=True)

    @action(detail=False, methods=['post'], url_path='import-excel')
    def import_excel(self, request):
        """Upload an Excel file and import breed references. Returns import log summary."""
        uploaded = request.FILES.get('file')
        if not uploaded:
            return Response({'detail': 'file required'}, status=status.HTTP_400_BAD_REQUEST)

        # save temporarily
        path = default_storage.save(f'tmp/{uploaded.name}', ContentFile(uploaded.read()))
        # default_storage.path may not be available in some deployments; prefer path value
        file_path = getattr(default_storage, 'path', lambda p: p)(path)

        log = BreedReferenceService.import_from_excel(file_path, request.user)

        serializer = ReferenceImportLogSerializer(log)
        return Response(serializer.data)
