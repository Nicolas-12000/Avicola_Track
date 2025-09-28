from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import FlockViewSet
from .views_weight import DailyWeightViewSet, ShedDashboardView
from .views_mortality import MortalityViewSet
from .views_conflict import SyncConflictViewSet
from .views import BreedReferenceViewSet

router = DefaultRouter()
router.register(r'flocks', FlockViewSet, basename='flock')
router.register(r'daily-weights', DailyWeightViewSet, basename='dailyweight')
router.register(r'mortality', MortalityViewSet, basename='mortality')
router.register(r'conflicts', SyncConflictViewSet, basename='conflict')
router.register(r'references', BreedReferenceViewSet, basename='breedreference')

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard/', ShedDashboardView.as_view(), name='shed-dashboard')
]
