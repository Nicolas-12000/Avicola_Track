/// Roles disponibles en el sistema AvícolaTrack
/// Deben coincidir exactamente con los nombres en el backend
enum UserRole {
  administradorSistema('Administrador Sistema'),
  administradorGranja('Administrador de Granja'),
  galponero('Galponero'),
  veterinario('Veterinario');

  final String name;
  const UserRole(this.name);

  /// Obtiene el rol desde un string (del backend)
  static UserRole? fromString(String? roleName) {
    if (roleName == null) return null;
    return UserRole.values.cast<UserRole?>().firstWhere(
      (role) => role?.name == roleName,
      orElse: () => null,
    );
  }

  /// Verifica si el rol tiene acceso de administrador general
  bool get isSystemAdmin => this == UserRole.administradorSistema;

  /// Verifica si el rol tiene acceso de administrador de granja
  bool get isFarmAdmin => this == UserRole.administradorGranja;

  /// Verifica si es un galponero (solo registra datos)
  bool get isShedKeeper => this == UserRole.galponero;

  /// Verifica si es veterinario
  bool get isVeterinarian => this == UserRole.veterinario;

  /// Retorna true si puede ver todas las granjas
  bool get canViewAllFarms => this == UserRole.administradorSistema;

  /// Retorna true si puede crear granjas
  bool get canCreateFarms => this == UserRole.administradorSistema;

  /// Retorna true si puede crear usuarios
  bool get canCreateUsers => 
      this == UserRole.administradorSistema || 
      this == UserRole.administradorGranja;

  /// Retorna true si puede ver reportes generales
  bool get canViewReports => 
      this == UserRole.administradorSistema || 
      this == UserRole.administradorGranja;

  /// Retorna true si puede registrar datos de lotes
  bool get canRecordFlockData =>
      this == UserRole.administradorSistema ||
      this == UserRole.administradorGranja ||
      this == UserRole.galponero;

  /// Retorna la ruta inicial según el rol
  String get initialRoute {
    switch (this) {
      case UserRole.administradorSistema:
        return '/';
      case UserRole.administradorGranja:
        return '/farms/dashboard';
      case UserRole.galponero:
        return '/shed-keeper-dashboard';
      case UserRole.veterinario:
        return '/veterinary';
    }
  }

  /// Descripción del rol para mostrar en UI
  String get description {
    switch (this) {
      case UserRole.administradorSistema:
        return 'Acceso completo al sistema';
      case UserRole.administradorGranja:
        return 'Administra una granja asignada';
      case UserRole.galponero:
        return 'Registra datos de galpones';
      case UserRole.veterinario:
        return 'Atiende solicitudes veterinarias';
    }
  }
}

/// Extensión para UserModel para trabajar con roles tipados
extension UserRoleExtension on String? {
  UserRole? get asUserRole => UserRole.fromString(this);
}
