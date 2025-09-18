from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FarmViewSet, HouseViewSet

router = DefaultRouter()
router.register(r'farms', FarmViewSet, basename='farm')
router.register(r'houses', HouseViewSet, basename='house')

urlpatterns = [
    path('', include(router.urls)),
]
