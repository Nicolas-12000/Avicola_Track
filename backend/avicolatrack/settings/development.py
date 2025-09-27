from .base import *

DEBUG = True
ALLOWED_HOSTS = ['127.0.0.1', 'localhost']

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
