import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/widgets/auth_error_banner.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!ref.read(connectivityServiceProvider).isOnline) {
      setState(() => _error = 'You are offline. Connect to change your password.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await ref.read(authViewModelProvider.notifier).changePassword(
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });

    if (error == null) {
      showAppSnackBar(
          context, 'Password changed. Other devices have been signed out.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('CHANGE PASSWORD')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Changing your password signs you out on every other device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _currentCtrl,
                  labelText: 'Current password',
                  enabled: !_saving,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter your current password'
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _newCtrl,
                  labelText: 'New password',
                  enabled: !_saving,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmCtrl,
                  labelText: 'Confirm new password',
                  enabled: !_saving,
                  validator: (v) =>
                      v != _newCtrl.text ? 'Passwords do not match' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: _error!),
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
                        : const Text('CHANGE PASSWORD'),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
