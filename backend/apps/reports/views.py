from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.http import FileResponse, Http404
from django.utils import timezone
from datetime import datetime, timedelta
import os

from .models import Report, ReportTemplate, ReportSchedule, ReportType
from .serializers import (
    ReportSerializer, ReportCreateSerializer, ReportTemplateSerializer,
    ReportScheduleSerializer, ProductivityReportRequestSerializer,
    ReportTypesSerializer
)
from .services import ProductivityReportService
from apps.users.permissions import CanAccessShed


class ReportViewSet(viewsets.ModelViewSet):
    """ViewSet para gestión de reportes"""
    
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ReportCreateSerializer
        return ReportSerializer
    
    def get_queryset(self):
        user = self.request.user
        
        # Filtrar por permisos de usuario
        if user.is_superuser:
            queryset = Report.objects.all()
        else:
            # Usuario solo ve reportes que ha creado o de sus fincas asignadas
            queryset = Report.objects.filter(created_by=user)
        
        # Filtros opcionales
        farm_id = self.request.query_params.get('farm')
        if farm_id:
            queryset = queryset.filter(farm_id=farm_id)
        
        report_type = self.request.query_params.get('type')
        if report_type:
            queryset = queryset.filter(report_type=report_type)
        
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        return queryset.select_related('farm', 'shed', 'flock', 'created_by')
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=False, methods=['get'])
    def types(self, request):
        """Lista los tipos de reportes disponibles"""
        report_types = []
        for choice in ReportType.choices:
            report_types.append(ReportType(choice[0]))
        
        serializer = ReportTypesSerializer(report_types, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def generate(self, request, pk=None):
        """Genera el reporte especificado"""
        report = self.get_object()
        
        if report.status != 'pending':
            return Response(
                {'error': 'El reporte ya ha sido procesado'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            if report.report_type == 'productivity':
                service = ProductivityReportService(report)
                data = service.generate_report()
                return Response(data)
            else:
                return Response(
                    {'error': f'Tipo de reporte {report.report_type} no implementado'},
                    status=status.HTTP_501_NOT_IMPLEMENTED
                )
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['get'])
    def download(self, request, pk=None):
        """Descarga el archivo del reporte si existe"""
        report = self.get_object()
        
        if not report.file_path or not os.path.exists(report.file_path):
            raise Http404("Archivo no encontrado")
        
        return FileResponse(
            open(report.file_path, 'rb'),
            as_attachment=True,
            filename=os.path.basename(report.file_path)
        )
    
    @action(detail=False, methods=['post'])
    def quick_productivity(self, request):
        """Genera un reporte de productividad rápido sin guardarlo"""
        serializer = ProductivityReportRequestSerializer(data=request.data)
        if serializer.is_valid():
            # Crear reporte temporal
            temp_report = Report(
                name=f"Reporte Temporal - {timezone.now().strftime('%Y-%m-%d %H:%M')}",
                report_type='productivity',
                farm=serializer.validated_data.get('farm'),
                shed=serializer.validated_data.get('shed'),
                flock=serializer.validated_data.get('flock'),
                date_from=serializer.validated_data['date_from'],
                date_to=serializer.validated_data['date_to'],
                created_by=request.user,
                export_format=serializer.validated_data.get('export_format', 'json'),
                include_charts=serializer.validated_data.get('include_charts', True)
            )
            
            try:
                service = ProductivityReportService(temp_report)
                data = service.generate_report()
                return Response(data)
            except Exception as e:
                return Response(
                    {'error': str(e)},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ReportTemplateViewSet(viewsets.ModelViewSet):
    """ViewSet para plantillas de reportes"""
    
    serializer_class = ReportTemplateSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ReportTemplate.objects.filter(is_active=True)
    
    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)
    
    @action(detail=True, methods=['post'])
    def create_report(self, request, pk=None):
        """Crea un reporte basado en la plantilla"""
        template = self.get_object()
        
        # Extraer parámetros del request
        farm_id = request.data.get('farm')
        shed_id = request.data.get('shed')
        flock_id = request.data.get('flock')
        date_from = request.data.get('date_from')
        date_to = request.data.get('date_to')
        
        if not date_from or not date_to:
            return Response(
                {'error': 'date_from y date_to son requeridos'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
            date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
        except ValueError:
            return Response(
                {'error': 'Formato de fecha inválido. Use YYYY-MM-DD'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Crear reporte basado en la plantilla
        report_data = {
            'name': f"{template.name} - {date_from} a {date_to}",
            'report_type': template.report_type,
            'date_from': date_from,
            'date_to': date_to,
            'export_format': request.data.get('export_format', 'excel'),
            'include_charts': request.data.get('include_charts', True)
        }
        
        if farm_id:
            report_data['farm'] = farm_id
        if shed_id:
            report_data['shed'] = shed_id
        if flock_id:
            report_data['flock'] = flock_id
        
        serializer = ReportCreateSerializer(data=report_data)
        if serializer.is_valid():
            report = serializer.save(created_by=request.user)
            return Response(ReportSerializer(report).data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ReportScheduleViewSet(viewsets.ModelViewSet):
    """ViewSet para programación de reportes"""
    
    serializer_class = ReportScheduleSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return ReportSchedule.objects.select_related('template')
    
    def perform_create(self, serializer):
        # Calcular próxima ejecución
        schedule = serializer.save(created_by=self.request.user)
        schedule.next_run = self._calculate_next_run(schedule)
        schedule.save()
    
    def _calculate_next_run(self, schedule):
        """Calcula la próxima fecha de ejecución"""
        now = timezone.now()
        next_run = now.replace(hour=schedule.hour, minute=0, second=0, microsecond=0)
        
        if schedule.frequency == 'daily':
            if next_run <= now:
                next_run += timedelta(days=1)
        elif schedule.frequency == 'weekly':
            days_ahead = schedule.day_of_week - next_run.weekday()
            if days_ahead <= 0:
                days_ahead += 7
            next_run += timedelta(days=days_ahead)
        elif schedule.frequency == 'monthly':
            if schedule.day_of_month <= next_run.day and next_run <= now:
                # Próximo mes
                if next_run.month == 12:
                    next_run = next_run.replace(year=next_run.year + 1, month=1, day=schedule.day_of_month)
                else:
                    next_run = next_run.replace(month=next_run.month + 1, day=schedule.day_of_month)
            else:
                next_run = next_run.replace(day=schedule.day_of_month)
        
        return next_run
    
    @action(detail=True, methods=['post'])
    def execute(self, request, pk=None):
        """Ejecuta manualmente una programación"""
        schedule = self.get_object()
        
        # Crear reporte basado en la programación
        now = timezone.now()
        if schedule.frequency == 'daily':
            date_from = now.date() - timedelta(days=1)
            date_to = now.date() - timedelta(days=1)
        elif schedule.frequency == 'weekly':
            date_from = now.date() - timedelta(days=7)
            date_to = now.date() - timedelta(days=1)
        elif schedule.frequency == 'monthly':
            date_from = now.date().replace(day=1) - timedelta(days=1)
            date_from = date_from.replace(day=1)
            date_to = now.date() - timedelta(days=1)
        else:
            return Response(
                {'error': 'Frecuencia no soportada'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        report_data = {
            'name': f"{schedule.template.name} - Automático {now.strftime('%Y-%m-%d')}",
            'report_type': schedule.template.report_type,
            'farm': schedule.farm.id if schedule.farm else None,
            'shed': schedule.shed.id if schedule.shed else None,
            'date_from': date_from,
            'date_to': date_to,
            'export_format': 'excel',
            'include_charts': True
        }
        
        serializer = ReportCreateSerializer(data=report_data)
        if serializer.is_valid():
            report = serializer.save(created_by=request.user)
            
            # Actualizar última ejecución
            schedule.last_run = now
            schedule.next_run = self._calculate_next_run(schedule)
            schedule.save()
            
            return Response(ReportSerializer(report).data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
