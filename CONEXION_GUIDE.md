# Guía de Configuración de Conexión Backend-Frontend

## Problema Común: Errores de Conexión

Si tienes errores de conexión entre el frontend (Flutter) y el backend (Django), sigue esta guía.

## Configuración del Backend (Django)

### 1. Ejecutar el servidor Django

```powershell
cd backend
# Activar entorno virtual si lo tienes
python manage.py runserver 0.0.0.0:8000
```

> ⚠️ **IMPORTANTE**: Usar `0.0.0.0:8000` en lugar de `127.0.0.1:8000` para que sea accesible desde otros dispositivos en la red.

### 2. Verificar configuración de settings

Asegúrate de estar usando el settings de desarrollo:

```powershell
$env:DJANGO_SETTINGS_MODULE = "avicolatrack.settings.development"
python manage.py runserver 0.0.0.0:8000
```

## Configuración del Frontend (Flutter)

### Configurar la URL del Backend

La URL del backend se configura de diferentes formas según el escenario:

#### Opción A: Emulador Android
```dart
// En api_constants.dart, usar:
defaultValue: 'http://10.0.2.2:8000/'
```

El `10.0.2.2` es la IP especial que el emulador Android usa para referirse al localhost de la máquina host.

#### Opción B: Dispositivo Físico (WiFi)
1. Obtén la IP de tu computadora:
   ```powershell
   ipconfig
   # Busca "IPv4 Address" en tu adaptador de red
   ```

2. Ejecuta Flutter con la variable de entorno:
   ```powershell
   flutter run --dart-define=API_BASE_URL=http://TU_IP:8000/
   ```

   Ejemplo:
   ```powershell
   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/
   ```

#### Opción C: iOS Simulator
```dart
defaultValue: 'http://localhost:8000/'
```

### Verificar Conectividad

La app ahora incluye un servicio de conectividad que:
1. Verifica si hay conexión a internet
2. Verifica si el backend está accesible
3. Muestra un banner cuando no hay conexión
4. Reintenta automáticamente las peticiones fallidas

## Solución de Problemas

### Error: "Connection refused"

**Causa**: El backend no está corriendo o no es accesible desde el dispositivo.

**Solución**:
1. Verifica que Django esté corriendo con `0.0.0.0:8000`
2. Verifica que ambos dispositivos estén en la misma red WiFi
3. Desactiva el firewall temporalmente para probar
4. Asegúrate de usar la IP correcta

### Error: "Connection timeout"

**Causa**: La red es muy lenta o hay un firewall bloqueando.

**Solución**:
1. Verifica tu conexión a internet
2. Intenta hacer ping al servidor desde el dispositivo
3. Revisa la configuración del firewall

### Error: "CORS error" (solo visible en logs)

**Causa**: El backend no permite peticiones desde el origen del frontend.

**Solución**: Ya está configurado en `development.py` con `CORS_ALLOW_ALL_ORIGINS = True`.

### Error: "401 Unauthorized"

**Causa**: Token expirado o inválido.

**Solución**: La app maneja esto automáticamente con refresh token. Si persiste, cierra sesión y vuelve a entrar.

## Comandos Útiles

### Backend
```powershell
# Ejecutar servidor de desarrollo
cd backend
$env:DJANGO_SETTINGS_MODULE = "avicolatrack.settings.development"
python manage.py runserver 0.0.0.0:8000

# Verificar migraciones
python manage.py migrate

# Crear superusuario
python manage.py createsuperuser
```

### Frontend
```powershell
# Ejecutar en emulador Android
cd frontend
flutter run

# Ejecutar con IP personalizada (dispositivo físico)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/

# Ejecutar en modo debug con logs
flutter run -v

# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```

## Arquitectura de Conexión

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                               │
├─────────────────────────────────────────────────────────────┤
│  ConnectivityService  │  Monitorea estado de red            │
│  ├─ checkConnection() │  Verifica internet + backend        │
│  └─ onStateChange     │  Stream de cambios                  │
├─────────────────────────────────────────────────────────────┤
│  Dio Client           │  Cliente HTTP                       │
│  ├─ ConnectivityInterceptor  │  Bloquea sin conexión        │
│  ├─ AuthInterceptor          │  Maneja tokens JWT           │
│  └─ RetryInterceptor         │  Reintenta errores de red    │
├─────────────────────────────────────────────────────────────┤
│  OfflineSyncService   │  Cola de operaciones offline        │
│  └─ syncAll()         │  Sincroniza cuando hay conexión     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Django Backend                            │
├─────────────────────────────────────────────────────────────┤
│  CORS Middleware      │  Permite requests cross-origin       │
│  JWT Authentication   │  Valida tokens de acceso             │
│  REST Framework       │  API endpoints                       │
└─────────────────────────────────────────────────────────────┘
```

## Flujo de una Petición

1. **Verificación de conectividad**: `ConnectivityInterceptor` verifica si hay conexión
2. **Agregar token**: `AuthInterceptor` agrega el token JWT al header
3. **Enviar petición**: Dio envía la petición al backend
4. **Manejo de errores**:
   - Si hay error 401: Intenta refresh token automáticamente
   - Si hay error de red: `RetryInterceptor` reintenta hasta 3 veces
   - Si falla: Muestra mensaje amigable al usuario

5. **Modo offline**: Si no hay conexión, las operaciones de escritura se guardan en cola local y se sincronizan cuando vuelve la conexión.
