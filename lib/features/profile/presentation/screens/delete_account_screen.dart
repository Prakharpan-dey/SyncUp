import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _canDelete = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    void update() {
      setState(() => _canDelete =
          _confirmCtrl.text == 'DELETE' && _passwordCtrl.text.isNotEmpty);
    }

    _confirmCtrl.addListener(update);
    _passwordCtrl.addListener(update);
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    if (!ref.read(connectivityServiceProvider).isOnline) {
      showAppSnackBar(
          context, 'You are offline. Connect to delete your account.',
          isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_rounded,
            size: 48, color: AppColors.error),
        title: const Text('ARE YOU ABSOLUTELY SURE?'),
        content: const Text(
          'This cannot be undone. Your tasks, attendance records, friends and '
          'group memberships are deleted immediately.\n\n'
          'Your email address and username become available again, so you can '
          'sign up fresh later if you change your mind.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _deleting = true);
              final success = await ref
                  .read(authViewModelProvider.notifier)
                  .deleteAccount(_passwordCtrl.text);
              if (mounted) {
                setState(() => _deleting = false);
                if (success) {
                  context.go('/auth/sign-in');
                } else {
                  final error = ref.read(authViewModelProvider).error;
                  showAppSnackBar(
                      context, error ?? 'Failed to delete account',
                      isError: true);
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('DELETE FOREVER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DELETE ACCOUNT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: NeoBrutalism.bannerDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                isDark: isDark,
              ),
              child: Column(
                children: [
                  const Icon(Icons.delete_forever_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'THIS IS PERMANENT',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deleting your account will remove all your data, '
                    'including tasks, attendance records, friends, and group memberships. '
                    'This cannot be undone.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'TYPE DELETE TO CONFIRM',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              enabled: !_deleting,
              decoration: const InputDecoration(
                hintText: 'Type DELETE here',
                prefixIcon: Icon(Icons.warning_amber_rounded),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            Text(
              _confirmCtrl.text == 'DELETE'
                  ? 'Confirmation matches'
                  : 'Type "DELETE" exactly',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _confirmCtrl.text == 'DELETE'
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'CONFIRM YOUR PASSWORD',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _passwordCtrl,
              labelText: 'Your password',
              enabled: !_deleting,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canDelete && !_deleting ? _confirmDelete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.error.withValues(alpha: 0.3),
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('DELETE MY ACCOUNT'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
