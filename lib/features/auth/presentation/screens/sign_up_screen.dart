import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/utils/validators.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/password_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authViewModelProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Container(
                  width: 64,
                  height: 64,
                  decoration: NeoBrutalism.iconBoxDecoration(
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      size: 32, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'CREATE ACCOUNT',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join SyncUp to stay productive',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _displayNameCtrl,
                  onChanged: (_) => ref
                      .read(authViewModelProvider.notifier)
                      .clearErrors(),
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: const Icon(Icons.person_outlined),
                    // Server-reported problem for this specific input, e.g.
                    // "Username already taken" — shown under the field that
                    // caused it rather than in the banner at the bottom.
                    errorText: authState.fieldErrors['display_name'],
                  ),
                  validator: Validators.displayName,
                  textCapitalization: TextCapitalization.words,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  onChanged: (_) => ref
                      .read(authViewModelProvider.notifier)
                      .clearErrors(),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    // Server-reported problem for this specific input, e.g.
                    // "Username already taken" — shown under the field that
                    // caused it rather than in the banner at the bottom.
                    errorText: authState.fieldErrors['username'],
                  ),
                  validator: Validators.username,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  onChanged: (_) => ref
                      .read(authViewModelProvider.notifier)
                      .clearErrors(),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    // Server-reported problem for this specific input, e.g.
                    // "Username already taken" — shown under the field that
                    // caused it rather than in the banner at the bottom.
                    errorText: authState.fieldErrors['email'],
                  ),
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _passwordCtrl,
                  onChanged: (_) => ref
                      .read(authViewModelProvider.notifier)
                      .clearErrors(),
                  // Server-reported problem for this specific input, e.g.
                  // "Username already taken" — shown under the field that
                  // caused it rather than in the banner at the bottom.
                  errorText: authState.fieldErrors['password'],
                  validator: Validators.password,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                // A typo here is only discovered at the next sign-in, by which
                // point the password is unknown — so it is worth confirming
                // once at creation.
                PasswordField(
                  controller: _confirmPasswordCtrl,
                  labelText: 'Confirm Password',
                  enabled: !isLoading,
                  validator: (value) => value != _passwordCtrl.text
                      ? 'Passwords do not match'
                      : null,
                ),
                // Only when the failure could not be attributed to a field —
                // otherwise the same sentence appears twice, once under the
                // offending input and again down here.
                if (authState.error != null &&
                    authState.fieldErrors.isEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: NeoBrutalism.bannerDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      isDark: isDark,
                    ),
                    child: Text(
                      authState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.status == AuthStatus.loading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(authViewModelProvider.notifier).signUp(
                                  _emailCtrl.text,
                                  _passwordCtrl.text,
                                  _usernameCtrl.text,
                                  _displayNameCtrl.text,
                                );
                          }
                        },
                  child: authState.status == AuthStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('CREATE ACCOUNT'),
                ),
                // Google Sign-In hidden for launch — see sign_in_screen.dart.
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => context.go('/auth/sign-in'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
