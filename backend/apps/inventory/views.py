from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction

from .models import InventoryItem
from .serializers import InventoryItemSerializer, BulkStockUpdateSerializer
from .permissions import CanManageInventory


class InventoryViewSet(viewsets.ModelViewSet):
    queryset = InventoryItem.objects.all()
    serializer_class = InventoryItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Simple permission scoping: admins see all; farm admins see their farm; workers see assigned sheds
        if hasattr(user, 'role') and user.role and user.role.name == 'Administrador Sistema':
            return InventoryItem.objects.all()

        if hasattr(user, 'role') and user.role and user.role.name == 'Administrador de Granja':
            # assume user has farm relationship
            return InventoryItem.objects.filter(farm__farm_manager=user)

        # Default: restrict to user's assigned sheds/farms
        return InventoryItem.objects.filter(farm__in=user.farms.all())

    @action(detail=False, methods=['get'], url_path='stock-alerts')
    def stock_alerts(self, request):
        user = request.user
        user_inventory = self.get_queryset()

        alerts = {'critical': [], 'low': [], 'out_of_stock': []}

        for item in user_inventory:
            status = item.stock_status['status']
            if status == 'OUT_OF_STOCK':
                alerts['out_of_stock'].append(self._serialize_alert(item))
            elif status == 'CRITICAL':
                alerts['critical'].append(self._serialize_alert(item))
            elif status == 'LOW':
                alerts['low'].append(self._serialize_alert(item))

        return Response({
            'alerts': alerts,
            'summary': {
                'total_items': user_inventory.count(),
                'critical_count': len(alerts['critical']),
                'low_count': len(alerts['low']),
                'out_of_stock_count': len(alerts['out_of_stock'])
            }
        })

    def _serialize_alert(self, item):
        return {
            'id': item.id,
            'name': item.name,
            'location': item.location_display,
            'current_stock': float(item.current_stock),
            'unit': item.unit,
            'status': item.stock_status,
            'projected_stockout': item.projected_stockout_date.isoformat() if item.projected_stockout_date else None
        }

    @action(detail=False, methods=['post'], url_path='bulk-update-stock', permission_classes=[IsAuthenticated, CanManageInventory])
    def bulk_update_stock(self, request):
        updates = request.data.get('stock_updates', [])
        results = []

        serializer = BulkStockUpdateSerializer(data=request.data, many=False)
        # We'll validate entries individually below

        with transaction.atomic():
            for update_data in updates:
                try:
                    bs = BulkStockUpdateSerializer(data=update_data)
                    bs.is_valid(raise_exception=True)
                    item = InventoryItem.objects.get(id=bs.validated_data['inventory_id'])

                    # Object-level permission check
                    if not CanManageInventory().has_object_permission(request, self, item):
                        raise PermissionError('Sin permisos para actualizar este inventario')

                    item.current_stock = bs.validated_data['new_stock']
                    item.save()
                    item.update_consumption_metrics()

                    results.append({'client_id': bs.validated_data.get('client_id'), 'status': 'success', 'new_stock': float(item.current_stock)})

                except Exception as e:
                    results.append({'client_id': update_data.get('client_id'), 'status': 'error', 'error': str(e)})

        return Response({'results': results})

    # uses CanManageInventory permission for object-level checks
from django.shortcuts import render

# Create your views here.
