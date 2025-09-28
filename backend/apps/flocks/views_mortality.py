from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiResponse, OpenApiExample

from .serializers_mortality import (
    MortalityBulkRequestSerializer,
    MortalityBulkResultSerializer
)
from .services import MortalityService


class MortalityViewSet(viewsets.ViewSet):
    @extend_schema(
        description='Sincroniza en bloque registros de mortalidad desde dispositivos móviles.',
        request=MortalityBulkRequestSerializer,
        responses=OpenApiResponse(response=MortalityBulkResultSerializer),
        examples=[
            OpenApiExample('Ejemplo mortalidad', value={
                'total': 2,
                'successful': 2,
                'errors': 0,
                'details': [
                    {'client_id': 'c1', 'server_id': 1, 'status': 'success', 'action': 'created'},
                    {'client_id': 'c2', 'server_id': 2, 'status': 'success', 'action': 'created'}
                ]
            })
        ]
    )
    @action(detail=False, methods=['post'], url_path='bulk-sync')
    def bulk_sync(self, request):
        payload = request.data.get('mortality_records', [])
        results = MortalityService.register_mortality_batch(payload, request.user)

        summary = {
            'total': len(payload),
            'successful': sum(1 for r in results if r.get('status') == 'success'),
            'errors': sum(1 for r in results if r.get('status') == 'error'),
            'details': results
        }

        return Response(summary)
