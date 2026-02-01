import '../../core/constants/user_roles.dart';

class UserModel {
  final int id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? identification;
  final String? phone;
  final String? role;
  final int? assignedFarm;
  final bool isActive;

  UserModel({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.identification,
    this.phone,
    this.role,
    this.assignedFarm,
    required this.isActive,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    if (username != null && username!.isNotEmpty) return username!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'Sin nombre';
  }
  
  /// Obtiene el rol tipado del usuario
  UserRole? get userRole => role.asUserRole;
  
  /// Verifica si es administrador del sistema
  bool get isSystemAdmin => userRole?.isSystemAdmin ?? false;
  
  /// Verifica si es administrador de granja
  bool get isFarmAdmin => userRole?.isFarmAdmin ?? false;
  
  /// Verifica si es galponero
  bool get isShedKeeper => userRole?.isShedKeeper ?? false;
  
  /// Verifica si es veterinario
  bool get isVeterinarian => userRole?.isVeterinarian ?? false;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '') ?? 0;

    final roleValue = json['role'];
    final role = _mapRole(roleValue);

    return UserModel(
      id: id,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      identification: json['identification'] as String?,
      phone: json['phone'] as String?,
      role: role,
      assignedFarm: json['assigned_farm'] as int?,
      isActive: json.containsKey('is_active') ? (json['is_active'] as bool) : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'identification': identification,
      'phone': phone,
      'role': role,
      'assigned_farm': assignedFarm,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? identification,
    String? phone,
    String? role,
    int? assignedFarm,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      identification: identification ?? this.identification,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedFarm: assignedFarm ?? this.assignedFarm,
      isActive: isActive ?? this.isActive,
    );
  }

  static String? _mapRole(dynamic roleValue) {
    // Backend may send: null, int ids, plain strings, or nested objects {name: '...'}
    if (roleValue == null) return null;

    if (roleValue is Map<String, dynamic>) {
      return roleValue['name'] as String?;
    }

    if (roleValue is int) {
      const roleById = {
        1: 'Administrador Sistema',
        2: 'Administrador de Granja',
        3: 'Veterinario',
        4: 'Galponero',
      };
      return roleById[roleValue];
    }

    if (roleValue is String) {
      switch (roleValue) {
        case 'Admin':
        case 'Administrador':
          return 'Administrador Sistema';
        case 'Farm Manager':
        case 'Gerente de Granja':
          return 'Administrador de Granja';
        case 'Worker':
        case 'Trabajador':
          return 'Galponero';
        case 'Veterinarian':
          return 'Veterinario';
        default:
          return roleValue;
      }
    }

    return null;
  }
}
