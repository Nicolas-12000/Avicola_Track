# AvicolaTrack - Frontend Flutter

Sistema de gestión avícola moderno y multiplataforma construido con Flutter 3.35.1 y Dart 3.9.0.

## 📋 Estado del Proyecto

**Fase Actual:** 1-2 (Autenticación y Dashboard Básico) ✅

### Completado
- ✅ Proyecto Flutter configurado con arquitectura limpia
- ✅ Sistema de diseño completo (theme, colores, tipografía)
- ✅ Dependencias instaladas y resueltas (196 paquetes)
- ✅ Core infrastructure (storage, utils, errors, widgets)
- ✅ Feature Auth (datasource, repository, provider, login screen)
- ✅ Flutter analyze sin errores
- ✅ Compilación exitosa

### En Progreso
- 🔄 Testing de la aplicación (ejecutando en Windows)
- 🔄 Router configuration (go_router)
- 🔄 Dashboard screens por rol

### Pendiente
- ⏳ Configuración de Firebase (FCM)
- ⏳ Features completos (Farms, Flocks, Inventory, Alarms, Reports)
- ⏳ Testing (unit, widget, integration)
- ⏳ Build runner para code generation (Freezed, JSON serialization)

## 🏗️ Arquitectura

### Clean Architecture + Feature-First

```
lib/
├── core/                    # Funcionalidad compartida
│   ├── theme/              # Sistema de diseño
│   ├── constants/          # Constantes globales
│   ├── storage/            # Secure storage (JWT)
│   ├── utils/              # Helpers y validadores
│   ├── errors/             # Error handling
│   └── widgets/            # Widgets reutilizables
├── data/                    # Modelos de datos globales
│   └── models/             # User, Auth
└── features/               # Features modulares
    ├── auth/
    │   ├── data/           # Data sources
    │   ├── domain/         # Repositories
    │   └── presentation/   # UI, Providers, Screens
    ├── dashboard/
    ├── farms/
    ├── flocks/
    ├── inventory/
    ├── alarms/
    ├── reports/
    └── users/
```

## 🎨 Sistema de Diseño

### Paleta de Colores
- **Primary:** Navy Blue (#1E3A5F) - Profesionalismo y confianza
- **Secondary:** Green (#4CAF50) - Crecimiento saludable
- **Accent:** Orange (#FF8A65) - Alertas y llamados a acción
- **Neutrals:** Grises para textos y fondos
- **Semantic:** Success, Warning, Error, Info

### Tipografía
Sistema completo de text styles (Display, Headline, Title, Body, Label, Caption) optimizado para Material Design 3.

## 🚀 Stack Tecnológico

### Core
- **Flutter:** 3.35.1 | **Dart:** 3.9.0

### Key Dependencies
- **State:** Riverpod 2.6.1
- **Routing:** go_router 14.8.1
- **Network:** Dio 5.9.0 + Retrofit 4.9.1
- **Storage:** Hive 2.2.3, flutter_secure_storage 9.2.4
- **Auth:** jwt_decoder 2.0.1, local_auth 2.3.0
- **UI:** google_fonts 6.3.3, fl_chart 0.69.2, flutter_animate 4.5.0
- **Firebase:** FCM push notifications
- **Export:** PDF, Excel, Printing

Ver [pubspec.yaml](pubspec.yaml) para lista completa.

## 📦 Instalación

### Setup Rápido

1. **Instalar dependencias:**
```bash
cd frontend
flutter pub get
```

2. **Verificar instalación:**
```bash
flutter doctor
flutter analyze
```

3. **Ejecutar la app:**
```bash
# Desktop Windows
flutter run -d windows

# Web
flutter run -d chrome

# Android/iOS
flutter run
```

## 🔧 Configuración

### API Backend
Editar `lib/core/constants/api_constants.dart`:
```dart
static const String BASE_URL = 'http://localhost:8000'; // Cambiar en producción
```

## 🧪 Testing
```bash
flutter test
```

## 📱 Features por Rol

### Administrador
Dashboard global, gestión de granjas/usuarios, reportes consolidados

### Gerente de Granja
Dashboard de granja, lotes/galpones, reportes de producción

### Galponero
Registro diario, alarmas del galpón, consulta de protocolos

### Veterinario
Dashboard de salud, tratamientos, historial médico

## 🎯 Roadmap

Ver [ROADMAP_FRONTEND.md](../backend/ROADMAP_FRONTEND.md) para plan detallado.

**Fases:**
1-2. Autenticación + Dashboard ✅ (ACTUAL)
3. Granjas y Usuarios
4. Lotes y Galpones
5. Inventario y Reportes
6. Alarmas y Notificaciones
7. Veterinaria
8. Analytics y ML

## 🐛 Problemas Conocidos

### Build Runner (Code Generation)
- `analyzer_plugin` incompatible con Dart 3.9.0 Element2 API
- **Workaround:** Modelos manuales sin Freezed por ahora
- **Impact:** Bajo - funcionalidad no afectada

## 📊 Métricas

- **Líneas de Código:** ~2,500
- **Archivos:** 30+
- **Dependencias:** 196 paquetes
- **Flutter Analyze:** ✅ 0 errores, 0 warnings

## 📚 Recursos

- [Roadmap Completo](../backend/ROADMAP_FRONTEND.md)
- [API Backend](http://localhost:8000/)
- [Flutter Docs](https://docs.flutter.dev/)
- [Riverpod](https://riverpod.dev/)

---

**Versión:** 0.1.0-alpha | **Estado:** En Desarrollo Activo | **2025**
