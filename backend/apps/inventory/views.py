from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.utils import timezone
from decimal import Decimal
from drf_spectacular.utils import extend_schema, OpenApiResponse

from .models import InventoryItem, FoodBatch, FoodConsumptionRecord
from .serializers import (
    InventoryItemSerializer, BulkStockUpdateSerializer, FoodBatchSerializer,
    FoodConsumptionRecordSerializer, FoodConsumptionRequestSerializer,
    BulkFoodConsumptionSerializer, FIFOConsumptionResultSerializer,
    AddStockSerializer
)
from .permissions import CanManageInventory
from apps.flocks.models import Flock


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

    @extend_schema(
        request=AddStockSerializer,
        responses=OpenApiResponse(response=FoodBatchSerializer)
    )
    @action(detail=True, methods=['post'], url_path='add-stock')
    def add_stock(self, request, pk=None):
        """Agregar stock creando un lote FIFO"""
        item = self.get_object()
        serializer = AddStockSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Crear lote FIFO
        batch = item.add_stock(
            quantity=serializer.validated_data['quantity'],
            entry_date=serializer.validated_data.get('entry_date')
        )
        
        # Actualizar campos opcionales del lote
        if serializer.validated_data.get('supplier'):
            batch.supplier = serializer.validated_data['supplier']
        if serializer.validated_data.get('lot_number'):
            batch.lot_number = serializer.validated_data['lot_number']
        if serializer.validated_data.get('expiry_date'):
            batch.expiry_date = serializer.validated_data['expiry_date']
        batch.save()
        
        return Response(FoodBatchSerializer(batch).data, status=status.HTTP_201_CREATED)

    @extend_schema(
        request=FoodConsumptionRequestSerializer,
        responses=OpenApiResponse(response=FIFOConsumptionResultSerializer)
    )
    @action(detail=True, methods=['post'], url_path='consume-fifo')
    def consume_fifo(self, request, pk=None):
        """Consumir stock usando FIFO estricto"""
        item = self.get_object()
        serializer = FoodConsumptionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        try:
            flock = Flock.objects.get(id=serializer.validated_data['flock_id'])
            
            # Realizar consumo FIFO
            consumption_record, fifo_details = item.consume_fifo(
                quantity_to_consume=serializer.validated_data['quantity_consumed'],
                flock=flock,
                user=request.user
            )
            
            # Actualizar campos opcionales
            if serializer.validated_data.get('date'):
                consumption_record.date = serializer.validated_data['date']
            if serializer.validated_data.get('client_id'):
                consumption_record.client_id = serializer.validated_data['client_id']
            consumption_record.save()
            
            return Response({
                'consumption_record_id': consumption_record.id,
                'fifo_details': fifo_details,
                'remaining_stock': float(item.current_stock)
            })
            
        except Flock.DoesNotExist:
            return Response({'error': 'Lote no encontrado'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['get'], url_path='fifo-batches')
    def fifo_batches(self, request, pk=None):
        """Obtener lotes FIFO de un item"""
        item = self.get_object()
        batches = item.food_batches.all().order_by('entry_date')
        return Response(FoodBatchSerializer(batches, many=True).data)

    @extend_schema(
        request=BulkFoodConsumptionSerializer,
        responses=OpenApiResponse(response=None)
    )
    @action(detail=False, methods=['post'], url_path='bulk-consume-fifo')
    def bulk_consume_fifo(self, request):
        """Sincronización masiva de consumo FIFO desde dispositivos móviles"""
        serializer = BulkFoodConsumptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        results = []
        
        with transaction.atomic():
            for consumption_data in serializer.validated_data['consumption_records']:
                try:
                    # Obtener objetos
                    flock = Flock.objects.get(id=consumption_data['flock_id'])
                    item = InventoryItem.objects.get(id=consumption_data['inventory_item_id'])
                    
                    # Verificar permisos
                    if not CanManageInventory().has_object_permission(request, self, item):
                        raise PermissionError('Sin permisos para este inventario')
                    
                    # Realizar consumo FIFO
                    consumption_record, fifo_details = item.consume_fifo(
                        quantity_to_consume=consumption_data['quantity_consumed'],
                        flock=flock,
                        user=request.user
                    )
                    
                    # Configurar campos adicionales
                    if consumption_data.get('date'):
                        consumption_record.date = consumption_data['date']
                    if consumption_data.get('client_id'):
                        consumption_record.client_id = consumption_data['client_id']
                    consumption_record.save()
                    
                    results.append({
                        'client_id': consumption_data.get('client_id'),
                        'server_id': consumption_record.id,
                        'status': 'success',
                        'fifo_details': fifo_details
                    })
                    
                except Exception as e:
                    results.append({
                        'client_id': consumption_data.get('client_id'),
                        'server_id': None,
                        'status': 'error',
                        'error': str(e)
                    })
        
        return Response({
            'total': len(serializer.validated_data['consumption_records']),
            'successful': len([r for r in results if r['status'] == 'success']),
            'errors': len([r for r in results if r['status'] == 'error']),
            'details': results
        })

    # uses CanManageInventory permission for object-level checks


class FoodBatchViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet para ver lotes de alimento (solo lectura)"""
    queryset = FoodBatch.objects.all().order_by('-entry_date')
    serializer_class = FoodBatchSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Filtrar según permisos de usuario
        if hasattr(user, 'role') and user.role and user.role.name == 'Administrador Sistema':
            return FoodBatch.objects.all().order_by('-entry_date')

        if hasattr(user, 'role') and user.role and user.role.name == 'Administrador de Granja':
            return FoodBatch.objects.filter(inventory_item__farm__farm_manager=user).order_by('-entry_date')

        # Default: restricción por galpones asignados
        return FoodBatch.objects.filter(inventory_item__shed__assigned_worker=user).order_by('-entry_date')


class FoodConsumptionRecordViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet para registros de consumo FIFO (solo lectura, creación via InventoryViewSet)"""
    queryset = FoodConsumptionRecord.objects.all().order_by('-date')
    serializer_class = FoodConsumptionRecordSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        # Filtrar según permisos de usuario
        if hasattr(user, 'role') and user.role and user.role.name == 'Administrador Sistema':
            return FoodConsumptionRecord.objects.all().order_by('-date')

        if hasattr(user, 'role') and user.role and user.role.name == 'Administrador de Granja':
            return FoodConsumptionRecord.objects.filter(flock__shed__farm__farm_manager=user).order_by('-date')

        # Default: solo registros de lotes asignados al galponero
        return FoodConsumptionRecord.objects.filter(flock__shed__assigned_worker=user).order_by('-date')

