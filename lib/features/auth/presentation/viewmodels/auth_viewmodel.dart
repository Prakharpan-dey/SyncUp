import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/guest_data_migrator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/auth/guest_session.dart';
import '../../../../core/di/core_providers.dart';
import '../../domain/entities/user.dart';
import '../../di/auth_providers.dart';

/// [guest] means "using the app locally with no account" — a deliberate choice,
/// distinct from [unauthenticated], which means "signed out, send to sign-in".
enum AuthStatus { initial, authenticated, unauthenticated, loading, guest }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  /// Server errors keyed by the field that caused them.
  ///
  /// A duplicate email, a duplicate username and a 422 all used to collapse
  /// into the single banner under a four-field form — the user was told
  /// something was wrong but not which box to fix.
  final Map<String, String> fieldErrors;

  /// Local identity when [status] is [AuthStatus.guest]; null otherwise.
  final String? guestId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.fieldErrors = const {},
    this.guestId,
  });

  bool get isGuest => status == AuthStatus.guest;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    Map<String, String>? fieldErrors,
    String? guestId,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        // Cleared alongside `error`, which is also reset on every attempt:
        // stale markers must not outlive the submission that produced them.
        fieldErrors: fieldErrors ?? const {},
        guestId: guestId ?? this.guestId,
      );
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    // The interceptor clears tokens when a refresh fails; without listening for
    // that, this state would keep reporting "authenticated" and the router
    // would leave the user stranded in an app where every request 401s.
    final subscription = ref
        .read(authInterceptorProvider)
        .onSessionExpired
        .listen((_) => _onSessionExpired());
    ref.onDispose(subscription.cancel);

    return const AuthState();
  }

  void _onSessionExpired() {
    // A guest has no session to lose — leave them where they are.
    if (state.status == AuthStatus.guest) return;

    state = const AuthState(
      status: AuthStatus.unauthenticated,
      error: 'Your session expired. Please sign in again.',
    );
  }

  /// Starts (or resumes) local-only use with no account.
  Future<void> enterGuestMode() async {
    final guestId = await ref.read(guestSessionProvider.notifier).start();
    state = AuthState(status: AuthStatus.guest, guestId: guestId);
  }

  /// Completes a successful sign-in.
  ///
  /// Any locally-created tasks and subjects are handed to the new account
  /// *before* the status flips, because screens re-query as soon as
  /// `currentUserIdProvider` changes — moving the rows afterwards would show
  /// the user an empty app for a beat.
  Future<void> _onAuthenticated(User user) async {
    final guestId = ref.read(guestSessionProvider.notifier).storedId;
    if (guestId != null) {
      await ref.read(guestDataMigratorProvider).migrate(
            guestId: guestId,
            accountId: user.id,
          );
      await ref.read(guestSessionProvider.notifier).end();
    }
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  void _onAuthFailed(Failure failure) {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      error: failure.message,
      fieldErrors: failure.fieldErrors,
    );
  }

  /// Drops the previous failure once the user starts changing the form.
  ///
  /// Server errors describe the values that were submitted. Leaving them up
  /// while the user edits marks a field they have already corrected — the
  /// username still reads "already taken" after being replaced with a free one.
  void clearErrors() {
    if (state.error == null && state.fieldErrors.isEmpty) return;
    state = state.copyWith(error: null, fieldErrors: const {});
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(signInUseCaseProvider)(
      email: email,
      password: password,
    );
    await result.fold(
      (f) async => _onAuthFailed(f),
      _onAuthenticated,
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
    await result.fold(
      (f) async => _onAuthFailed(f),
      _onAuthenticated,
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
      (f) => state = _signedOutState(),
      (user) {
        state = user != null
            ? AuthState(status: AuthStatus.authenticated, user: user)
            : _signedOutState();
      },
    );
  }

  /// With no valid session, resume guest mode if that is how the app was last
  /// used — otherwise a guest would be bounced to sign-in on every cold start.
  AuthState _signedOutState() {
    final guestId = ref.read(guestSessionProvider);
    return guestId != null
        ? AuthState(status: AuthStatus.guest, guestId: guestId)
        : const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> deleteAccount(String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(deleteAccountUseCaseProvider)(password);
    return result.fold(
      (f) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          error: f.message,
        );
        return false;
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return true;
      },
    );
  }

  // ── Email verification ──

  /// Re-sends the verification link. Returns true if the address was already
  /// confirmed, in which case the local user is refreshed to match.
  Future<bool?> resendVerificationEmail() async {
    final result =
        await ref.read(authRepositoryProvider).requestEmailVerification();
    return result.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return null;
      },
      (alreadyVerified) {
        if (alreadyVerified) unawaited(checkAuthStatus());
        return alreadyVerified;
      },
    );
  }

  Future<bool> confirmEmailVerification(String token) async {
    final result = await ref
        .read(authRepositoryProvider)
        .confirmEmailVerification(token);

    return result.fold(
      (f) async {
        state = state.copyWith(error: f.message);
        return false;
      },
      (_) async {
        // Pull the updated emailVerifiedAt so the social surface unlocks.
        await checkAuthStatus();
        return true;
      },
    );
  }

  // ── Password ──

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref.read(authRepositoryProvider).forgotPassword(email);
    return result.fold(
      (f) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: f.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return true;
      },
    );
  }

  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(token: token, password: password);
    return result.fold(
      (f) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: f.message,
        );
        return false;
      },
      (_) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return true;
      },
    );
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    // Returns the error message, or null on success — the caller shows it
    // inline rather than through global auth state.
    return result.fold((f) => f.message, (_) => null);
  }

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    state = state.copyWith(error: null);
    final result =
        await ref.read(authRepositoryProvider).updateProfile(fields);
    return result.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (user) {
        state = state.copyWith(user: user);
        return true;
      },
    );
  }
}

// Manual provider registration
final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
