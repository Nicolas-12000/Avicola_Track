from rest_framework.routers import DefaultRouter
from .views import (
    AlarmConfigurationViewSet, 
    AlarmViewSet, 
    AlarmManagementViewSet,
    NotificationLogViewSet
)

router = DefaultRouter()
router.register(r'configs', AlarmConfigurationViewSet, basename='alarmconfig')
router.register(r'alarms', AlarmViewSet, basename='alarm')
router.register(r'manage/alarms', AlarmManagementViewSet, basename='alarm-management')
router.register(r'notifications', NotificationLogViewSet, basename='notifications')

urlpatterns = router.urls
