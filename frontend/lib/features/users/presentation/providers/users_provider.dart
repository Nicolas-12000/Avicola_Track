import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/user_model.dart';
import '../../data/user_datasource.dart';
import '../../domain/user_repository.dart';

// DataSource Provider
final userDataSourceProvider = Provider<UserDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return UserDataSource(dio);
});

// Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(userDataSourceProvider);
  return UserRepository(dataSource);
});

// Users State
class UsersState {
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  UsersState({this.users = const [], this.isLoading = false, this.error});

  UsersState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Users Notifier
class UsersNotifier extends StateNotifier<UsersState> {
  final UserRepository _repository;

  UsersNotifier(this._repository) : super(UsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getUsers();

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
    } else {
      state = state.copyWith(
        users: result.users ?? [],
        isLoading: false,
        error: null,
      );
    }
  }

  Future<bool> createUser({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String identification,
    required String phone,
    required String role,
    int? assignedFarm,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createUser(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      identification: identification,
      phone: phone,
      role: role,
      assignedFarm: assignedFarm,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
      return false;
    }

    // Recargar lista
    await loadUsers();
    return true;
  }

  Future<bool> updateUser({
    required int id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? identification,
    String? phone,
    String? role,
    int? assignedFarm,
    bool? isActive,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateUser(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      identification: identification,
      phone: phone,
      role: role,
      assignedFarm: assignedFarm,
      isActive: isActive,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
      return false;
    }

    // Recargar lista
    await loadUsers();
    return true;
  }

  Future<bool> deleteUser(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    final failure = await _repository.deleteUser(id);

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure.message);
      return false;
    }

    // Recargar lista
    await loadUsers();
    return true;
  }
}

// Users Provider
final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UsersNotifier(repository);
});
