import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_error_banner.dart';

/// Shown when an unverified account reaches the social surface.
///
/// Tasks and attendance stay available without verifying — only friends,
/// groups and the feed are gated, so an unverified account cannot pose as
/// someone by registering with their address.
///
/// [token] is set when the user arrives from the link in their email, in which
/// case the screen confirms immediately rather than waiting for a tap.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String? token;

  const EmailVerificationScreen({super.key, this.token});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _busy = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      Future.microtask(() => _confirm(widget.token!));
    }
  }

  Future<void> _confirm(String token) async {
    setState(() {
      _busy = true;
      _notice = null;
    });

    final ok = await ref
        .read(authViewModelProvider.notifier)
        .confirmEmailVerification(token);

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified. Social features unlocked.')),
      );
      context.go('/home');
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _notice = null;
    });

    final alreadyVerified =
        await ref.read(authViewModelProvider.notifier).resendVerificationEmail();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _notice = switch (alreadyVerified) {
        true => 'This address is already verified.',
        false => 'Sent. Check your inbox.',
        null => null, // failed — the error banner covers it
      };
    });

    if (alreadyVerified == true && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: NeoBrutalism.iconBoxDecoration(
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'VERIFY YOUR EMAIL',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(letterSpacing: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
                child: Column(
                  children: [
                    Text(
                      'We sent a link to\n${user?.email ?? 'your email'}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confirm it to add friends, join groups and see your feed. '
                      'Your tasks and attendance work either way.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (_notice != null) ...[
                const SizedBox(height: 16),
                Text(
                  _notice!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.success),
                ),
              ],
              if (authState.error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: authState.error!),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _busy
                    ? null
                    : () =>
                        ref.read(authViewModelProvider.notifier).checkAuthStatus(),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('I VERIFIED MY EMAIL'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _busy ? null : _resend,
                child: const Text('RESEND VERIFICATION EMAIL'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _busy ? null : () => context.go('/home'),
                child: const Text('Continue without verifying'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await ref.read(authViewModelProvider.notifier).logout();
                        if (context.mounted) context.go('/auth/sign-in');
                      },
                child: const Text('Sign in with a different account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
