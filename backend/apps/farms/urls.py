from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FarmViewSet, ShedViewSet

router = DefaultRouter()
router.register(r'sheds', ShedViewSet, basename='shed')
router.register(r'farms', FarmViewSet, basename='farm')

urlpatterns = [path('', include(router.urls))]
