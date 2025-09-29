from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'reports', views.ReportViewSet, basename='report')
router.register(r'templates', views.ReportTemplateViewSet, basename='reporttemplate')
router.register(r'schedules', views.ReportScheduleViewSet, basename='reportschedule')

urlpatterns = [
    path('', include(router.urls)),
]