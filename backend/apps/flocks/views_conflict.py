from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiResponse
from drf_spectacular.utils import OpenApiExample
from django.utils import timezone

from .models import SyncConflict
from .serializers_conflict import SyncConflictSerializer, ResolveConflictSerializer


class SyncConflictViewSet(viewsets.ModelViewSet):
    queryset = SyncConflict.objects.all().order_by('-created_at')
    # Provide a serializer for schema generation and simple CRUD
    serializer_class = SyncConflictSerializer

    def list(self, request, *args, **kwargs):
        """
        List unresolved sync conflicts.
        """
        conflicts = self.queryset.filter(resolved_at__isnull=True)
        data = [
            {
                'id': c.id,
                'source': c.source,
                'client_id': c.client_id,
                'payload': c.payload,
                'resolution': c.resolution,
                'flock': c.flock.id if c.flock else None,
                'resolved_by': c.resolved_by.id if c.resolved_by else None,
                'resolved_at': c.resolved_at,
            }
            for c in conflicts
        ]
        return Response(data)

    @extend_schema(request=ResolveConflictSerializer)
    @extend_schema(
        description='Resolver un conflicto detectado durante la sincronización. Marcará el conflicto como resuelto y registrará el usuario que lo resolvió.',
        examples=[
            OpenApiExample(
                'Ejemplo resolve',
                value={'resolution': 'manual', 'note': 'Revisado y fusionado'}
            )
        ]
    )
    @action(detail=True, methods=['post'], url_path='resolve')
    def resolve(self, request, pk=None):
        conflict = self.get_object()
        serializer = ResolveConflictSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        resolution = serializer.validated_data['resolution']

        conflict.resolution = resolution
        conflict.resolved_by = request.user
        conflict.resolved_at = timezone.now()
        conflict.save()

        return Response({'status': 'resolved', 'id': conflict.id})
