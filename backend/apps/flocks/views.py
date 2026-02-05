from rest_framework import viewsets, permissions
from .models import Flock
from .serializers import FlockSerializer
from .permissions import IsAssignedShedWorkerOrFarmAdmin


class FlockViewSet(viewsets.ModelViewSet):
    queryset = Flock.objects.all()
    serializer_class = FlockSerializer
    permission_classes = [permissions.IsAuthenticated, IsAssignedShedWorkerOrFarmAdmin]

    def get_queryset(self):
        user = self.request.user
        role_name = getattr(getattr(user, 'role', None), 'name', None)

        # Start from all flocks and allow filtering by query params
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

        # Apply role-based restrictions
        if user.is_staff or role_name == 'Administrador Sistema':
            return qs
        if role_name == 'Administrador de Granja':
            return qs.filter(shed__farm__farm_manager=user)
        if role_name == 'Galponero':
            return qs.filter(shed__assigned_worker=user)

        return Flock.objects.none()
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
