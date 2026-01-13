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
    // Manejar el rol que puede venir como String o como objeto
    String? roleValue;
    if (json['role'] is String) {
      roleValue = json['role'] as String?;
    } else if (json['role'] is Map) {
      roleValue = json['role']?['name'] as String?;
    }
    
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      identification: json['identification'] as String?,
      phone: json['phone'] as String?,
      role: roleValue,
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
}
