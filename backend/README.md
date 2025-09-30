# AvícolaTrack Backend

API REST para el sistema de gestión avícola AvícolaTrack, desarrollada con Django REST Framework.

## 📋 Descripción

AvícolaTrack Backend es un sistema completo de gestión avícola que permite el control y monitoreo de granjas, galpones, lotes de aves, inventario, alarmas y reportes. Diseñado específicamente para optimizar la gestión en entornos rurales con conectividad limitada.

## 🚀 Características Principales

### 🏢 Gestión de Granjas
- Administración de granjas y galpones
- Control de capacidad y asignación de trabajadores
- Gestión de usuarios con roles específicos

### 🐔 Gestión de Lotes (Flocks)
- Control completo del ciclo de vida de lotes de aves
- Seguimiento de mortalidad y peso
- Sistema FIFO para rotación de lotes
- Referencias automáticas de razas

### 📦 Gestión de Inventario
- Control de alimento y consumo
- Gestión por lotes con fechas de vencimiento
- Importación masiva desde Excel
- Sistema de alertas por stock bajo

### 🚨 Sistema de Alarmas
- Monitoreo automático de indicadores críticos
- Escalamiento automático de alarmas
- Notificaciones por email y sistema interno
- Configuración flexible de umbrales

### 📊 Sistema de Reportes
- Reportes de productividad, mortalidad y consumo
- Exportación a Excel, PDF y CSV
- Programación automática de reportes
- Plantillas personalizables

### 🔄 Sincronización de Datos
- Detección y resolución de conflictos automática
- Sistema de versionado para datos críticos
- Sincronización optimizada para conexiones lentas

## 🛠️ Tecnologías

- **Framework**: Django 5.2.6
- **API**: Django REST Framework
- **Base de Datos**: SQLite (desarrollo) / 
- **Autenticación**: JWT con django-rest-framework-simplejwt
- **Documentación**: drf-spectacular (OpenAPI/Swagger)
- **Tareas Asíncronas**: Celery + Redis
- **Testing**: pytest + pytest-django
- **Cache**: Redis

## 📦 Instalación

### Prerrequisitos
- Python 3.12+
- pip
- Git

### Configuración del Entorno

1. **Clonar el repositorio**
```bash
git clone https://github.com/Nicolas-12000/Avicola_Track.git
cd Avicola_Track/backend
```

2. **Crear y activar entorno virtual**
```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
# Linux/Mac
source .venv/bin/activate
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar variables de entorno**
```bash
# Crear archivo .env en el directorio backend/
DJANGO_SECRET_KEY=tu-clave-secreta-aqui
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
REDIS_URL=redis://localhost:6379/0
```

5. **Aplicar migraciones**
```bash
python manage.py migrate
```

6. **Crear superusuario**
```bash
python manage.py createsuperuser
```

7. **Ejecutar servidor de desarrollo**
```bash
python manage.py runserver
```

## 🧪 Testing

El proyecto cuenta con una suite completa de 44 tests que cubren todas las funcionalidades principales.

### Ejecutar todos los tests
```bash
pytest -q
```

### Ejecutar tests con detalle
```bash
pytest -v
```

### Ejecutar tests por aplicación
```bash
pytest apps/flocks/ -v
pytest apps/inventory/ -v
pytest apps/alarms/ -v
```

### Cobertura de tests
```bash
pytest --cov=apps --cov-report=html
```

## 📁 Estructura del Proyecto

```
backend/
├── avicolatrack/           # Configuración principal de Django
│   ├── settings/          # Configuraciones por entorno
│   ├── urls.py           # URLs principales
│   └── wsgi.py           # WSGI configuration
├── apps/                  # Aplicaciones Django
│   ├── users/            # Gestión de usuarios y autenticación
│   ├── farms/            # Granjas y galpones
│   ├── flocks/           # Lotes de aves
│   ├── inventory/        # Inventario y alimentos
│   ├── alarms/           # Sistema de alarmas
│   ├── reports/          # Sistema de reportes
│   └── sync/             # Sincronización de datos
├── docs/                 # Documentación OpenAPI
├── scripts/              # Scripts de utilidad
└── requirements.txt      # Dependencias del proyecto
```

## 🔧 Configuración

### Entornos
- **Development**: `avicolatrack.settings.development`
- **Production**: `avicolatrack.settings.production`

### Base de Datos
- **Desarrollo**: SQLite (por defecto)
- **Producción**: 

### Cache y Tareas Asíncronas
- **Redis**: Para cache y broker de Celery
- **Celery**: Para tareas en segundo plano
- **Celery Beat**: Para tareas programadas

## 🔌 API Endpoints

### Autenticación
- `POST /api/auth/login/` - Iniciar sesión
- `POST /api/auth/refresh/` - Renovar token
- `POST /api/auth/logout/` - Cerrar sesión

### Granjas
- `GET /api/farms/` - Listar granjas
- `POST /api/farms/` - Crear granja
- `GET/PUT/DELETE /api/farms/{id}/` - CRUD granja específica

### Lotes
- `GET /api/flocks/` - Listar lotes
- `POST /api/flocks/` - Crear lote
- `GET /api/flocks/dashboard/` - Dashboard de lotes
- `POST /api/flocks/bulk-sync/` - Sincronización masiva

### Inventario
- `GET /api/inventory/` - Gestión de inventario
- `POST /api/inventory/import/` - Importar desde Excel
- `GET /api/inventory/breed-references/` - Referencias de razas

### Alarmas
- `GET /api/alarms/` - Listar alarmas
- `POST /api/alarms/acknowledge/` - Confirmar alarma
- `GET /api/alarms/configurations/` - Configuraciones

### Reportes
- `GET /api/reports/` - Listar reportes
- `POST /api/reports/generate/` - Generar reporte
- `GET /api/reports/types/` - Tipos de reportes

### Documentación
- `GET /api/schema/` - Esquema OpenAPI
- `GET /api/docs/` - Documentación Swagger UI

## 🔍 Funcionalidades Destacadas

### Sistema FIFO
- Rotación automática de lotes por fecha de llegada
- Optimización para granjas con múltiples galpones

### Referencias Automáticas de Razas
- Actualización automática de referencias de peso y consumo
- Importación masiva desde archivos Excel
- Versionado de referencias para trazabilidad

### Detección de Conflictos
- Sistema automático de detección de conflictos en sincronización
- Resolución inteligente basada en timestamps y prioridades
- Notificaciones automáticas a usuarios relevantes

### Optimización Rural
- Compresión de datos para conexiones lentas
- Sincronización incremental
- Cache inteligente para reducir consultas

## 🚨 Monitoreo y Alarmas

### Tipos de Alarmas
- **Mortalidad Alta**: Detección automática de mortalidad anormal
- **Peso Bajo**: Alerta por peso por debajo de referencias
- **Stock Bajo**: Notificación de inventario insuficiente
- **Consumo Anormal**: Detección de patrones de consumo irregulares

### Escalamiento
- Notificación inmediata a supervisores
- Escalamiento automático si no se atiende
- Registro completo de acciones tomadas

## 📈 Desarrollo

### Agregar Nueva Aplicación
```bash
python manage.py startapp nueva_app apps/nueva_app
```

### Crear Migraciones
```bash
python manage.py makemigrations
python manage.py migrate
```

### Ejecutar Shell de Django
```bash
python manage.py shell
```

### Recopilar Archivos Estáticos
```bash
python manage.py collectstatic
```

## 🔒 Seguridad

- Autenticación JWT con refresh tokens
- Permisos granulares por rol de usuario
- Validación de datos de entrada
- Rate limiting en endpoints críticos
- CORS configurado para frontend

## 📝 Logging

Los logs se configuran por entorno:
- **DEBUG**: Logs detallados para desarrollo
- **INFO**: Información general de funcionamiento
- **WARNING**: Alertas de funcionamiento
- **ERROR**: Errores que requieren atención

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Autores

- **Nicolas Garcia** - *Desarrollador Principal* - [@Nicolas-12000](https://github.com/Nicolas-12000)

## 🙏 Agradecimientos

- Django REST Framework por proporcionar un framework robusto
- La comunidad de Django por las herramientas y mejores prácticas
- OpenAPI/Swagger por la documentación automática de APIs

---

**AvícolaTrack Backend v0.8.0** - Sistema de Gestión Avícola Integral