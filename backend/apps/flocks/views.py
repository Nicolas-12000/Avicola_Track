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

        if user.is_staff or role_name == 'Administrador Sistema':
            return Flock.objects.all()
        if role_name == 'Administrador de Granja':
            return Flock.objects.filter(shed__farm__farm_manager=user)
        if role_name == 'Galponero':
            return Flock.objects.filter(shed__assigned_worker=user)

        return Flock.objects.none()
from django.shortcuts import render

# Create your views here.
