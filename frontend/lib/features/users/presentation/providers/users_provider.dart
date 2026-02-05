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
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMoreData;
  final String? searchQuery;

  static const int pageSize = 20;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
    this.searchQuery,
  });

  UsersState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMoreData,
    String? searchQuery,
    bool clearError = false,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Usuarios filtrados por búsqueda
  List<UserModel> get filteredUsers {
    if (searchQuery == null || searchQuery!.isEmpty) return users;
    final q = searchQuery!.toLowerCase();
    return users.where((u) =>
      u.displayName.toLowerCase().contains(q) ||
      (u.email?.toLowerCase().contains(q) ?? false) ||
      (u.username?.toLowerCase().contains(q) ?? false)
    ).toList();
  }
}

// Users Notifier
class UsersNotifier extends StateNotifier<UsersState> {
  final UserRepository _repository;

  UsersNotifier(this._repository) : super(UsersState());

  Future<void> loadUsers({bool refresh = true}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMoreData: true,
        clearError: true,
      );
    }

    final result = await _repository.getUsers();

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
    } else {
      final users = result.users ?? [];
      state = state.copyWith(
        users: users,
        isLoading: false,
        error: null,
        hasMoreData: users.length >= UsersState.pageSize,
        clearError: true,
      );
    }
  }

  Future<void> loadMoreUsers() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _repository.getUsers();

    if (result.failure != null) {
      state = state.copyWith(isLoadingMore: false, error: result.failure!.message);
    } else {
      final newUsers = result.users ?? [];
      final allUsers = [...state.users, ...newUsers];
      state = state.copyWith(
        users: allUsers,
        isLoadingMore: false,
        currentPage: state.currentPage + 1,
        hasMoreData: newUsers.length >= UsersState.pageSize,
        clearError: true,
      );
    }
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> createUser({
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
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createUser(
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
    int? roleId,
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
      roleId: roleId,
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

  /// Obtener lista de galponeros
  Future<List<UserModel>> getGalponeros() async {
    final result = await _repository.getGalponeros();
    if (result.failure != null) {
      return [];
    }
    return result.users ?? [];
  }
}

// Users Provider
final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UsersNotifier(repository);
});

/// Provider para obtener galponeros
final galponerosProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  final result = await repository.getGalponeros();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.users ?? [];
});
