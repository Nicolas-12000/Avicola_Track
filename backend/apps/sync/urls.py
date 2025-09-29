from rest_framework.routers import DefaultRouter
from .views import SyncConflictViewSet

router = DefaultRouter()
router.register(r'conflicts', SyncConflictViewSet, basename='sync-conflict')

urlpatterns = router.urls
