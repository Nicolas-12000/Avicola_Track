from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    VeterinaryVisitViewSet,
    VaccinationRecordViewSet,
    MedicationViewSet,
    DiseaseViewSet,
    BiosecurityChecklistViewSet
)

router = DefaultRouter()
router.register(r'visits', VeterinaryVisitViewSet, basename='veterinary-visit')
router.register(r'vaccinations', VaccinationRecordViewSet, basename='vaccination')
router.register(r'medications', MedicationViewSet, basename='medication')
router.register(r'diseases', DiseaseViewSet, basename='disease')
router.register(r'biosecurity-checklists', BiosecurityChecklistViewSet, basename='biosecurity-checklist')

urlpatterns = [
    path('', include(router.urls)),
]
