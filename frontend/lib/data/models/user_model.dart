class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? identification;
  final String? phone;
  final String? role;
  final int? assignedFarm;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.identification,
    this.phone,
    this.role,
    this.assignedFarm,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      identification: json['identification'] as String?,
      phone: json['phone'] as String?,
      role: json['role']?['name'] as String?,
      assignedFarm: json['assigned_farm'] as int?,
      isActive: json['is_active'] as bool? ?? true,
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
