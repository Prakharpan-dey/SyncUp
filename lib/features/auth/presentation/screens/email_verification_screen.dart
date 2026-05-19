import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final user = authState.user;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to\n${user?.email ?? 'your email'}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Check if email is now verified
                  ref.read(authViewModelProvider.notifier).checkAuthStatus();
                },
                child: const Text('I verified my email'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // TODO: Call resend verification email endpoint
                },
                child: const Text('Resend verification email'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await ref.read(authViewModelProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/auth/sign-in');
                  }
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
