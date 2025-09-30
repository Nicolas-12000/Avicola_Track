from django.shortcuts import render
from django.db import models
from rest_framework import viewsets, permissions, status
from .models import SyncConflict
from .serializers import SyncConflictSerializer
from rest_framework.decorators import action
from rest_framework.response import Response
from .services import ConflictResolutionService

class SyncConflictViewSet(viewsets.ModelViewSet):
	queryset = SyncConflict.objects.all().order_by('-created_at')
	serializer_class = SyncConflictSerializer
	permission_classes = [permissions.IsAuthenticated]

	@action(detail=True, methods=['post'])
	def resolve(self, request, pk=None):
		conflict = self.get_object()
		resolution_type = request.data.get('resolution_type')
		resolution_data = request.data.get('resolution_data', {})

		if resolution_type not in ['server', 'client', 'manual', 'ignore']:
			return Response({'error': 'Tipo de resolución inválido'}, status=status.HTTP_400_BAD_REQUEST)

		result = ConflictResolutionService.resolve_conflict(conflict, resolution_type, resolution_data, request.user)

		return Response({'result': result})

# Create your views here.
