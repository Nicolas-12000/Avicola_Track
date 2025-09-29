from rest_framework.routers import DefaultRouter
from .views import AlarmConfigurationViewSet, AlarmViewSet

router = DefaultRouter()
router.register(r'configs', AlarmConfigurationViewSet, basename='alarmconfig')
router.register(r'alarms', AlarmViewSet, basename='alarm')

urlpatterns = router.urls
