from rest_framework.routers import DefaultRouter
from .views import AlarmConfigurationViewSet, AlarmViewSet, AlarmManagementViewSet

router = DefaultRouter()
router.register(r'configs', AlarmConfigurationViewSet, basename='alarmconfig')
router.register(r'alarms', AlarmViewSet, basename='alarm')
router.register(r'manage/alarms', AlarmManagementViewSet, basename='alarm-management')

urlpatterns = router.urls
