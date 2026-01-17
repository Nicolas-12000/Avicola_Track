from .base import *

DEBUG = True

# Permitir todas las hosts en desarrollo (incluyendo IPs locales para dispositivos físicos)
ALLOWED_HOSTS = [
    '127.0.0.1',
    'localhost',
    '10.0.2.2',       # Emulador Android
    '10.0.3.2',       # Genymotion
    '*',              # Cualquier IP (necesario para dispositivos en red local)
]

# Development-specific settings
from pathlib import Path

# Use SQLite in development to avoid requiring a local MySQL server
BASE_DIR = Path(__file__).resolve().parent.parent
DATABASES = {
	'default': {
		'ENGINE': 'django.db.backends.sqlite3',
		'NAME': BASE_DIR / 'db.sqlite3',
	}
}

# Development cache override: use local in-memory cache so services like
# django-ratelimit don't require a running Redis instance during local dev.
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-dev-cache',
    }
}

# Ensure django-ratelimit uses the local cache name
RATELIMIT_USE_CACHE = 'default'

# ============================================================
# CORS Configuration for Development
# ============================================================
# Permitir todas las orígenes en desarrollo para facilitar pruebas
# con emuladores, dispositivos físicos y diferentes IPs
CORS_ALLOW_ALL_ORIGINS = True

# Headers adicionales permitidos
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
    'cache-control',
    'pragma',
]

# Permitir credenciales (cookies, headers de auth)
CORS_ALLOW_CREDENTIALS = True

# Métodos HTTP permitidos
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

# Tiempo de cache para preflight requests (1 hora)
CORS_PREFLIGHT_MAX_AGE = 3600

# ============================================================
# Logging mejorado para desarrollo
# ============================================================
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'DEBUG',
    },
    'loggers': {
        'django.request': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
        'corsheaders': {
            'handlers': ['console'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}

