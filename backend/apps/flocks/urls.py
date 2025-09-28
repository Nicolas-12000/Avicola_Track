from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import FlockViewSet
from .views_weight import DailyWeightViewSet, ShedDashboardView
from .views_mortality import MortalityViewSet
from .views_conflict import SyncConflictViewSet

router = DefaultRouter()
router.register(r'flocks', FlockViewSet, basename='flock')
router.register(r'daily-weights', DailyWeightViewSet, basename='dailyweight')
router.register(r'mortality', MortalityViewSet, basename='mortality')
router.register(r'conflicts', SyncConflictViewSet, basename='conflict')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', ShedDashboardView.as_view(), name='shed-dashboard')
]
