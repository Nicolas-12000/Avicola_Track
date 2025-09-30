from rest_framework import serializers
from .models import Report, ReportTemplate, ReportSchedule, ReportType
from apps.farms.models import Farm, Shed
from apps.flocks.models import Flock


class ReportSerializer(serializers.ModelSerializer):
    farm_name = serializers.CharField(source='farm.name', read_only=True)
    shed_name = serializers.CharField(source='shed.name', read_only=True)
    flock_name = serializers.CharField(source='flock.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    report_type_display = serializers.CharField(source='get_report_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    duration_days = serializers.ReadOnlyField()
    
    class Meta:
        model = Report
        fields = [
            'id', 'name', 'report_type', 'report_type_display',
            'status', 'status_display', 'farm', 'farm_name',
            'shed', 'shed_name', 'flock', 'flock_name',
            'date_from', 'date_to', 'duration_days',
            'created_by', 'created_by_name', 'created_at', 'updated_at',
            'data', 'file_path', 'error_message',
            'export_format', 'include_charts'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'data', 'file_path', 'error_message']


class ReportCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Report
        fields = [
            'name', 'report_type', 'farm', 'shed', 'flock',
            'date_from', 'date_to', 'export_format', 'include_charts'
        ]
    
    def validate(self, data):
        if data['date_from'] > data['date_to']:
            raise serializers.ValidationError("La fecha de inicio debe ser menor a la fecha de fin")
        
        # Validar que el shed pertenezca a la farm si ambos están especificados
        if data.get('farm') and data.get('shed'):
            if data['shed'].farm != data['farm']:
                raise serializers.ValidationError("El galpón seleccionado no pertenece a la finca especificada")
        
        # Validar que el flock pertenezca al shed si ambos están especificados
        if data.get('shed') and data.get('flock'):
            if data['flock'].shed != data['shed']:
                raise serializers.ValidationError("El lote seleccionado no pertenece al galpón especificado")
        
        return data


class ReportTemplateSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    report_type_display = serializers.CharField(source='get_report_type_display', read_only=True)
    
    class Meta:
        model = ReportTemplate
        fields = [
            'id', 'name', 'report_type', 'report_type_display',
            'description', 'configuration', 'is_active',
            'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at']


class ReportScheduleSerializer(serializers.ModelSerializer):
    template_name = serializers.CharField(source='template.name', read_only=True)
    farm_name = serializers.CharField(source='farm.name', read_only=True)
    shed_name = serializers.CharField(source='shed.name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    frequency_display = serializers.CharField(source='get_frequency_display', read_only=True)
    
    class Meta:
        model = ReportSchedule
        fields = [
            'id', 'name', 'template', 'template_name',
            'frequency', 'frequency_display', 'day_of_week', 'day_of_month', 'hour',
            'farm', 'farm_name', 'shed', 'shed_name',
            'is_active', 'last_run', 'next_run', 'recipients',
            'created_by', 'created_by_name', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'last_run', 'next_run']


class ProductivityReportRequestSerializer(serializers.Serializer):
    """Serializer para generar reportes de productividad específicos"""
    farm = serializers.PrimaryKeyRelatedField(queryset=Farm.objects.all(), required=False)
    shed = serializers.PrimaryKeyRelatedField(queryset=Shed.objects.all(), required=False)
    flock = serializers.PrimaryKeyRelatedField(queryset=Flock.objects.all(), required=False)
    date_from = serializers.DateField()
    date_to = serializers.DateField()
    
    # Métricas a incluir
    include_weight = serializers.BooleanField(default=True)
    include_mortality = serializers.BooleanField(default=True)
    include_consumption = serializers.BooleanField(default=True)
    include_conversion = serializers.BooleanField(default=True)
    include_production = serializers.BooleanField(default=False)  # Para ponedoras
    
    # Opciones de exportación
    export_format = serializers.ChoiceField(
        choices=[('json', 'JSON'), ('excel', 'Excel'), ('pdf', 'PDF')],
        default='json'
    )
    include_charts = serializers.BooleanField(default=True)
    compare_with_standards = serializers.BooleanField(default=True)
    
    def validate(self, data):
        if data['date_from'] > data['date_to']:
            raise serializers.ValidationError("La fecha de inicio debe ser menor a la fecha de fin")
        
        # Validar que el shed pertenezca a la farm si ambos están especificados
        if data.get('farm') and data.get('shed'):
            if data['shed'].farm != data['farm']:
                raise serializers.ValidationError("El galpón seleccionado no pertenece a la finca especificada")
        
        # Validar que el flock pertenezca al shed si ambos están especificados
        if data.get('shed') and data.get('flock'):
            if data['flock'].shed != data['shed']:
                raise serializers.ValidationError("El lote seleccionado no pertenece al galpón especificado")
        
        return data


class ReportTypesSerializer(serializers.Serializer):
    """Serializer para listar tipos de reportes disponibles"""
    value = serializers.CharField()
    label = serializers.CharField()
    description = serializers.CharField()
    
    def to_representation(self, instance):
        descriptions = {
            'productivity': 'Análisis completo de productividad incluyendo peso, mortalidad y conversión alimenticia',
            'mortality': 'Reporte detallado de mortalidad por causas y tendencias',
            'weight': 'Análisis de evolución de peso y comparación con estándares',
            'consumption': 'Consumo de alimento y eficiencia alimenticia',
            'inventory': 'Estado de inventario y proyecciones de stock',
            'alarms': 'Reporte de alarmas generadas y resolución',
            'financial': 'Análisis financiero de costos y rentabilidad'
        }
        
        return {
            'value': instance.value,
            'label': instance.label,
            'description': descriptions.get(instance.value, 'Reporte especializado')
        }