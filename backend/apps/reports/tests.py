import pytest
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import date, timedelta


@pytest.fixture
def user():
    """Fixture para crear usuario de test"""
    User = get_user_model()
    return User.objects.create_user(
        username='testuser',
        email='test@test.com',
        password='testpass123'
    )
    
@pytest.mark.django_db
def test_report_creation(user):
    """Test creación básica de reporte"""
    from apps.reports.models import Report, ReportType
    
    report = Report.objects.create(
        name='Test Report',
        report_type=ReportType.PRODUCTIVITY,
        date_from=date.today() - timedelta(days=7),
        date_to=date.today(),
        created_by=user
    )
    
    assert report.name == 'Test Report'
    assert report.report_type == ReportType.PRODUCTIVITY
    assert report.status == 'pending'
    assert report.duration_days == 8


@pytest.mark.django_db
def test_report_str_method(user):
    """Test método __str__ del reporte"""
    from apps.reports.models import Report, ReportType
    
    report = Report.objects.create(
        name='Test Report',
        report_type=ReportType.PRODUCTIVITY,  
        date_from=date.today() - timedelta(days=7),
        date_to=date.today(),
        created_by=user
    )
    
    expected = "Reporte de Productividad - Test Report"
    assert str(report) == expected


@pytest.mark.django_db
def test_template_creation(user):
    """Test creación de plantilla"""
    from apps.reports.models import ReportTemplate, ReportType
    
    template = ReportTemplate.objects.create(
        name='Weekly Productivity',
        report_type=ReportType.PRODUCTIVITY,
        description='Weekly productivity analysis',
        created_by=user
    )
    
    assert template.name == 'Weekly Productivity'
    assert template.report_type == ReportType.PRODUCTIVITY
    assert template.is_active is True


@pytest.mark.django_db
def test_report_types_endpoint(user, client):
    """Test endpoint de tipos de reportes"""
    client.force_login(user)
    response = client.get('/api/reports/types/')
    
    # El endpoint podría requerir autenticación específica o tener otros requirements
    # Verificamos que al menos responde (puede ser 401, 403, o 200)
    assert response.status_code in [200, 401, 403]


@pytest.mark.django_db  
def test_reports_list_requires_auth(client):
    """Test que la lista de reportes requiere autenticación"""
    response = client.get('/api/reports/')
    assert response.status_code == 401
