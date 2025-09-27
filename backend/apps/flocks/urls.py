from rest_framework.routers import DefaultRouter
from .views import FlockViewSet

router = DefaultRouter()
router.register(r'flocks', FlockViewSet, basename='flock')

urlpatterns = router.urls
