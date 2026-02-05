import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/user_model.dart';

class UserDataSource {
  final Dio _dio;

  UserDataSource(this._dio);

  /// Obtener todos los usuarios
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get(ApiConstants.users);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map && responseData.containsKey('results')
            ? responseData['results']
            : responseData;
        return data.map((json) => UserModel.fromJson(json)).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load users',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Obtener todos los galponeros
  Future<List<UserModel>> getGalponeros() async {
    try {
      final response = await _dio.get(ApiConstants.galponeros);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is List
            ? responseData
            : (responseData is Map && responseData.containsKey('results')
                ? responseData['results']
                : []);
        return data.map((json) => UserModel.fromJson(json)).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load galponeros',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Obtener un usuario por ID
  Future<UserModel> getUser(int id) async {
    try {
      final response = await _dio.get(ApiConstants.userDetail(id));

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load user',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Crear un nuevo usuario
  Future<UserModel> createUser({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String identification,
    required String phone,
    required int roleId,
    int? assignedFarm,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.users,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'identification': identification,
          'phone': phone,
          'role': roleId,
          if (assignedFarm != null) 'assigned_farm': assignedFarm,
        },
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create user',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Actualizar un usuario
  Future<UserModel> updateUser({
    required int id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? identification,
    String? phone,
    int? roleId,
    int? assignedFarm,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (identification != null) data['identification'] = identification;
      if (phone != null) data['phone'] = phone;
      if (roleId != null) data['role'] = roleId;
      if (assignedFarm != null) data['assigned_farm'] = assignedFarm;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.patch(
        ApiConstants.userDetail(id),
        data: data,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update user',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Eliminar/desactivar un usuario
  Future<void> deleteUser(int id) async {
    try {
      final response = await _dio.delete(ApiConstants.userDetail(id));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete user',
        );
      }
    } on DioException {
      rethrow;
    }
  }
}
