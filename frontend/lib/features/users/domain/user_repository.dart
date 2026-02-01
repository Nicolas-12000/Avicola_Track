import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/user_model.dart';
import '../data/user_datasource.dart';

class UserRepository {
  final UserDataSource _dataSource;

  UserRepository(this._dataSource);

  Future<({List<UserModel>? users, Failure? failure})> getUsers() async {
    try {
      final users = await _dataSource.getUsers();
      return (users: users, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          users: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        users: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to load users',
        ),
      );
    } catch (e) {
      return (users: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<({UserModel? user, Failure? failure})> getUser(int id) async {
    try {
      final user = await _dataSource.getUser(id);
      return (user: user, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          user: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        user: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to load user',
        ),
      );
    } catch (e) {
      return (user: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<({UserModel? user, Failure? failure})> createUser({
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
      final user = await _dataSource.createUser(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        identification: identification,
        phone: phone,
        roleId: roleId,
        assignedFarm: assignedFarm,
      );
      return (user: user, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          user: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        user: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to create user',
        ),
      );
    } catch (e) {
      return (user: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<({UserModel? user, Failure? failure})> updateUser({
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
      final user = await _dataSource.updateUser(
        id: id,
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        identification: identification,
        phone: phone,
        roleId: roleId,
        assignedFarm: assignedFarm,
        isActive: isActive,
      );
      return (user: user, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          user: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        user: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to update user',
        ),
      );
    } catch (e) {
      return (user: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<Failure?> deleteUser(int id) async {
    try {
      await _dataSource.deleteUser(id);
      return null;
    } on DioException catch (e) {
      if (e.response == null) {
        return const NetworkFailure(message: 'No internet connection');
      }
      return ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to delete user',
      );
    } catch (e) {
      return ServerFailure(message: e.toString());
    }
  }
}
