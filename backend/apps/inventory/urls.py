from rest_framework.routers import DefaultRouter
from .views import InventoryViewSet, FoodBatchViewSet, FoodConsumptionRecordViewSet

router = DefaultRouter()
router.register(r'inventory', InventoryViewSet, basename='inventory')
router.register(r'food-batches', FoodBatchViewSet, basename='foodbatch')
router.register(r'food-consumption', FoodConsumptionRecordViewSet, basename='foodconsumption')

urlpatterns = router.urls
