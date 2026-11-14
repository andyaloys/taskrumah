import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(storageServiceProvider);
  return AuthRepository(client, storage);
});

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkInitialAuth();
    return AuthState.initial();
  }

  Future<void> _checkInitialAuth() async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.getCachedUser();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateAvatar(String newAvatarUrl) async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(avatarUrl: newAvatarUrl);
      final storage = ref.read(storageServiceProvider);
      await storage.saveUser(updatedUser.toJson());
      state = state.copyWith(user: updatedUser);
    }
  }

  Future<void> refreshProfile() async {
    if (state.user != null) {
      try {
        final client = ref.read(apiClientProvider);
        final res = await client.dio.get('/users/${state.user!.id}');
        final updatedUser = UserModel.fromJson(res.data as Map<String, dynamic>);
        final storage = ref.read(storageServiceProvider);
        await storage.saveUser(updatedUser.toJson());
        state = state.copyWith(user: updatedUser);
      } catch (_) {}
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
