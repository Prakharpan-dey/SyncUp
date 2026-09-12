import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/utils/validators.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/password_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';

/// Reached from the link in a password-reset email.
///
/// The token in the URL *is* the credential, so this screen is reachable
/// without being signed in.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // The auth state is shared by every auth screen. An error from the one
    // before (a wrong password on sign-in) is not about this screen.
    Future.microtask(() {
      if (mounted) ref.read(authViewModelProvider.notifier).clearErrors();
    });
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final ok = await ref.read(authViewModelProvider.notifier).resetPassword(
          token: widget.token,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      showAppSnackBar(
          context, 'Password updated. Sign in with your new password.');
      context.go('/auth/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = ref.watch(authViewModelProvider).error;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: NeoBrutalism.iconBoxDecoration(
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                  child: const Icon(Icons.key_rounded,
                      size: 32, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text('NEW PASSWORD',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Choose a new password. You will be signed out everywhere '
                  'else once it is set.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 28),
                PasswordField(
                  controller: _passwordCtrl,
                  labelText: 'New password',
                  enabled: !_saving,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmCtrl,
                  labelText: 'Confirm new password',
                  enabled: !_saving,
                  validator: (value) => value != _passwordCtrl.text
                      ? 'Passwords do not match'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: error),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('SET NEW PASSWORD'),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      _saving ? null : () => context.go('/auth/sign-in'),
                  child: const Text('BACK TO SIGN IN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
