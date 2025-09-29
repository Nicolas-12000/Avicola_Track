from rest_framework import viewsets, permissions
from .models import AlarmConfiguration, Alarm
from .serializers import AlarmConfigurationSerializer, AlarmSerializer


class AlarmConfigurationViewSet(viewsets.ModelViewSet):
    queryset = AlarmConfiguration.objects.all()
    serializer_class = AlarmConfigurationSerializer
    permission_classes = [permissions.IsAuthenticated]


class AlarmViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Alarm.objects.all().order_by('-created_at')
    serializer_class = AlarmSerializer
    permission_classes = [permissions.IsAuthenticated]
from django.shortcuts import render

# Create your views here.
