from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import FlockViewSet
from .views_weight import DailyWeightViewSet, ShedDashboardView

router = DefaultRouter()
router.register(r'flocks', FlockViewSet, basename='flock')
router.register(r'daily-weights', DailyWeightViewSet, basename='dailyweight')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', ShedDashboardView.as_view(), name='shed-dashboard')
]
