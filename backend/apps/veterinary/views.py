from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import timedelta
from django.db.models import Q, Count
from .models import (
    VeterinaryVisit,
    VaccinationRecord,
    Medication,
    Disease,
    BiosecurityChecklist
)
from .serializers import (
    VeterinaryVisitSerializer,
    VaccinationRecordSerializer,
    MedicationSerializer,
    DiseaseSerializer,
    BiosecurityChecklistSerializer
)


class VeterinaryVisitViewSet(viewsets.ModelViewSet):
    serializer_class = VeterinaryVisitSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = VeterinaryVisit.objects.all().prefetch_related('flocks')
        farm_id = self.request.query_params.get('farm_id')
        flock_id = self.request.query_params.get('flock_id')
        status_param = self.request.query_params.get('status')
        
        if farm_id:
            queryset = queryset.filter(farm_id=farm_id)
        if flock_id:
            queryset = queryset.filter(flocks__id=flock_id)
        if status_param:
            queryset = queryset.filter(status=status_param)
            
        return queryset
    
    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        visit = self.get_object()
        visit.diagnosis = request.data.get('diagnosis')
        visit.treatment = request.data.get('treatment')
        visit.notes = request.data.get('notes')
        visit.photo_urls = request.data.get('photo_urls', [])
        visit.status = 'completed'
        visit.completed_at = timezone.now()
        visit.save()
        
        serializer = self.get_serializer(visit)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='today_upcoming')
    def today_upcoming(self, request):
        """Obtener visitas de hoy y próximas 7 días"""
        today = timezone.now().date()
        upcoming_end = today + timedelta(days=7)
        
        queryset = VeterinaryVisit.objects.filter(
            visit_date__date__gte=today,
            visit_date__date__lte=upcoming_end
        ).order_by('visit_date').prefetch_related('flocks')
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class VaccinationRecordViewSet(viewsets.ModelViewSet):
    serializer_class = VaccinationRecordSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = VaccinationRecord.objects.all()
        flock_id = self.request.query_params.get('flock_id')
        status_param = self.request.query_params.get('status')
        
        if flock_id:
            queryset = queryset.filter(flock_id=flock_id)
        if status_param:
            queryset = queryset.filter(status=status_param)
            
        return queryset
    
    @action(detail=True, methods=['post'])
    def apply(self, request, pk=None):
        vaccination = self.get_object()
        vaccination.applied_date = timezone.now()
        vaccination.applied_by_id = request.data.get('applied_by')
        vaccination.bird_count = request.data.get('bird_count')
        vaccination.notes = request.data.get('notes')
        vaccination.status = 'applied'
        vaccination.save()
        
        serializer = self.get_serializer(vaccination)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        days_ahead = int(request.query_params.get('days_ahead', 7))
        end_date = timezone.now() + timedelta(days=days_ahead)
        
        queryset = VaccinationRecord.objects.filter(
            status='scheduled',
            scheduled_date__lte=end_date,
            scheduled_date__gte=timezone.now()
        )
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class MedicationViewSet(viewsets.ModelViewSet):
    serializer_class = MedicationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Medication.objects.all()
        flock_id = self.request.query_params.get('flock_id')
        status_param = self.request.query_params.get('status')
        
        if flock_id:
            queryset = queryset.filter(flock_id=flock_id)
        if status_param:
            queryset = queryset.filter(status=status_param)
            
        return queryset
    
    @action(detail=True, methods=['post'])
    def record_application(self, request, pk=None):
        medication = self.get_object()
        application_date = request.data.get('application_date')
        notes = request.data.get('notes')
        
        application_dates = medication.application_dates or []
        application_dates.append({
            'date': application_date,
            'notes': notes
        })
        medication.application_dates = application_dates
        medication.save()
        
        serializer = self.get_serializer(medication)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        queryset = Medication.objects.filter(status='active')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def withdrawal(self, request):
        now = timezone.now()
        queryset = Medication.objects.filter(
            status='active',
            withdrawal_end_date__gte=now
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class DiseaseViewSet(viewsets.ModelViewSet):
    queryset = Disease.objects.all()
    serializer_class = DiseaseSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Disease.objects.all()
        category = self.request.query_params.get('category')
        severity = self.request.query_params.get('severity')
        
        if category:
            queryset = queryset.filter(category=category)
        if severity:
            queryset = queryset.filter(severity=severity)
            
        return queryset
    
    @action(detail=False, methods=['get'])
    def search(self, request):
        query = request.query_params.get('q', '')
        queryset = Disease.objects.filter(
            Q(name__icontains=query) |
            Q(scientific_name__icontains=query) |
            Q(description__icontains=query)
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class BiosecurityChecklistViewSet(viewsets.ModelViewSet):
    serializer_class = BiosecurityChecklistSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = BiosecurityChecklist.objects.all()
        farm_id = self.request.query_params.get('farm_id')
        shed_id = self.request.query_params.get('shed_id')
        checklist_type = self.request.query_params.get('checklist_type')
        
        if farm_id:
            queryset = queryset.filter(farm_id=farm_id)
        if shed_id:
            queryset = queryset.filter(shed_id=shed_id)
        if checklist_type:
            queryset = queryset.filter(checklist_type=checklist_type)
            
        return queryset
    
    @action(detail=False, methods=['get'])
    def compliance_stats(self, request):
        farm_id = request.query_params.get('farm_id')
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        queryset = BiosecurityChecklist.objects.filter(farm_id=farm_id)
        
        if start_date:
            queryset = queryset.filter(performed_date__gte=start_date)
        if end_date:
            queryset = queryset.filter(performed_date__lte=end_date)
        
        stats = queryset.aggregate(
            total=Count('id'),
            completed=Count('id', filter=Q(status='completed')),
            failed=Count('id', filter=Q(status='failed'))
        )
        
        if stats['total'] > 0:
            stats['compliance_rate'] = (stats['completed'] / stats['total']) * 100
        else:
            stats['compliance_rate'] = 0
            
        return Response(stats)
