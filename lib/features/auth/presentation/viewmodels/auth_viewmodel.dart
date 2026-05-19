import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../di/auth_providers.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;
  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(signInUseCaseProvider)(
      email: email,
      password: password,
    );
    result.fold(
      (f) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: f.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> signUp(
    String email,
    String password,
    String username,
    String displayName,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(signUpUseCaseProvider)(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
    result.fold(
      (f) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: f.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(googleSignInUseCaseProvider)();
    result.fold(
      (f) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: f.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(logoutUseCaseProvider)();
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
    );
  }

  Future<void> checkAuthStatus() async {
    final result = await ref.read(getCurrentUserUseCaseProvider)();
    result.fold(
      (f) => state = const AuthState(status: AuthStatus.unauthenticated),
      (user) {
        if (user != null) {
          state = AuthState(status: AuthStatus.authenticated, user: user);
        } else {
          state = const AuthState(status: AuthStatus.unauthenticated);
        }
      },
    );
  }
}

// Manual provider registration
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
