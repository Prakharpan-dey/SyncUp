import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/utils/validators.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/check_your_inbox.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

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
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = ref.watch(authViewModelProvider).error;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/auth/sign-in'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              // Deliberately the same message whether or not the address is
              // registered — the API does not disclose which, and neither
              // should the UI.
              ? CheckYourInbox(
                  email: _emailCtrl.text.trim(),
                  message:
                      'If that address has a SyncUp account, a reset link is on '
                      'its way. The link expires in an hour.',
                  onDone: () => context.go('/auth/sign-in'),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: NeoBrutalism.iconBoxDecoration(
                          color: AppColors.warning,
                          isDark: isDark,
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            size: 32, color: Colors.black),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'FORGOT PASSWORD',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the email you signed up with and we will send a '
                        'link to set a new password.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: !_sending,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: Validators.email,
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
                          onPressed: _sending ? null : _submit,
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('SEND RESET LINK'),
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
