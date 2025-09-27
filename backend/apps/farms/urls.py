from rest_framework.routers import DefaultRouter
from .views import ShedViewSet

router = DefaultRouter()
router.register(r'sheds', ShedViewSet, basename='shed')

urlpatterns = router.urls
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import FarmViewSet

router = DefaultRouter()
router.register('farms', FarmViewSet, basename='farm')

urlpatterns = [
    path('', include(router.urls)),
]
