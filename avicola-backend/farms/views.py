from rest_framework import viewsets, permissions
from .models import Farm, House
from .serializers import FarmSerializer, HouseSerializer


class FarmViewSet(viewsets.ModelViewSet):
    queryset = Farm.objects.all()
    serializer_class = FarmSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'ADMIN':
            return Farm.objects.all()
        elif user.role == 'VETERINARIAN':
            return Farm.objects.filter(responsible=user)
        else:
            return Farm.objects.filter(houses__responsible=user).distinct()


class HouseViewSet(viewsets.ModelViewSet):
    queryset = House.objects.all()
    serializer_class = HouseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'ADMIN':
            return House.objects.all()
        elif user.role == 'VETERINARIAN':
            return House.objects.filter(farm__responsible=user)
        else:
            return House.objects.filter(responsible=user)
from django.shortcuts import render

# Create your views here.
