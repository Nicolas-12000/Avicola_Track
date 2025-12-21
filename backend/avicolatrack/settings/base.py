import os
from pathlib import Path

# Base dir
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'replace-me-with-secure-key')
DEBUG = False
ALLOWED_HOSTS = os.environ.get('DJANGO_ALLOWED_HOSTS', 'localhost').split(',')

# Apps
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'drf_spectacular',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'django_redis',
    'apps.users',
    'apps.farms',
    'apps.flocks',
    'apps.inventory',
    'apps.alarms',
    'apps.reports',
    'apps.sync',
    'apps.veterinary',
    
    # Celery Beat
    'django_celery_beat',
]

# Middleware optimized for slow links
MIDDLEWARE = [
    'django.middleware.gzip.GZipMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'avicolatrack.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'avicolatrack.wsgi.application'

# Database - default to MySQL with options suitable for rural zones
DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.mysql'),
        'NAME': os.environ.get('MYSQL_DATABASE', 'avicolatrack'),
        'USER': os.environ.get('MYSQL_USER', 'root'),
        'PASSWORD': os.environ.get('MYSQL_PASSWORD', ''),
        'HOST': os.environ.get('MYSQL_HOST', '127.0.0.1'),
        'PORT': os.environ.get('MYSQL_PORT', '3306'),
        'OPTIONS': {
            'charset': 'utf8mb4',
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
        },
        'CONN_MAX_AGE': int(os.environ.get('CONN_MAX_AGE', '600')),
    }
}

# Cache for master data
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.environ.get('REDIS_URL', 'redis://127.0.0.1:6379/1'),
        'TIMEOUT': int(os.environ.get('CACHE_TIMEOUT', '300')),
        'OPTIONS': {'CLIENT_CLASS': 'django_redis.client.DefaultClient'},
    }
}

# Password validators
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'es-co'
TIME_ZONE = 'America/Bogota'
USE_I18N = True
USE_L10N = True
USE_TZ = True

STATIC_URL = '/static/'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Custom user model placeholder
# AUTH_USER_MODEL must be 'app_label.ModelName' where app_label is the app's label (usually the last
# part of the AppConfig.name). Our apps live under package `apps` but the app label is 'users'.
AUTH_USER_MODEL = 'users.User'

# DRF settings optimized for mobile and slow connections
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    # Use drf-spectacular for OpenAPI schema generation
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

# SIMPLE JWT configuration (tokens tailored for mobile/offline use)
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=8),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}

# drf-spectacular OpenAPI settings
SPECTACULAR_SETTINGS = {
    'TITLE': 'AvícolaTrack API',
    'DESCRIPTION': '''# AvícolaTrack API Documentation

    ## Descripción General
    API REST completa para el sistema de gestión avícola AvícolaTrack. 
    Este sistema permite la administración integral de granjas avícolas, incluyendo:
    
    - 🏢 **Gestión de Granjas**: Administración de granjas, galpones y trabajadores
    - 🐔 **Gestión de Lotes**: Control completo del ciclo de vida de lotes de aves
    - 📦 **Inventario**: Control de alimento, consumo y stock
    - 🚨 **Alarmas**: Monitoreo automático e indicadores críticos
    - 📊 **Reportes**: Generación de reportes automatizados
    - 🔄 **Sincronización**: Sistema de sincronización para dispositivos móviles
    
    ## Autenticación
    La API utiliza autenticación JWT (JSON Web Tokens). Para acceder a los endpoints protegidos:
    
    1. Obtén un token usando `/api/auth/login/`
    2. Incluye el token en el header: `Authorization: Bearer <token>`
    3. Renueva el token usando `/api/auth/refresh/` cuando sea necesario
    ''',
    'VERSION': '9.0.0',
    'SERVERS': [
        {'url': 'http://localhost:8000', 'description': 'Servidor de desarrollo local'},
    ],
    'CONTACT': {
        'name': 'Nicolas Garcia',
        'url': 'https://github.com/Nicolas-12000',
    },
    'SERVE_INCLUDE_SCHEMA': False,
}

# Email backend for development (prints to console)
EMAIL_BACKEND = os.environ.get('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')

# Basic logging for audit
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': os.environ.get('LOG_LEVEL', 'INFO'),
    },
}

# Celery Configuration (Redis as broker)
CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL', 'redis://127.0.0.1:6379/0')
CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND', 'redis://127.0.0.1:6379/0')
CELERY_ACCEPT_CONTENT = ['application/json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE

# CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:8080",
    "http://localhost:5000",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8080",
    "http://127.0.0.1:5000",
]

# For development, allow all origins (configure properly for production)
CORS_ALLOW_ALL_ORIGINS = os.environ.get('CORS_ALLOW_ALL', 'False').lower() == 'true'

CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'
