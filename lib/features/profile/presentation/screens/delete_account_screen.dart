import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  bool _canDelete = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() {
      setState(() => _canDelete = _confirmCtrl.text == 'DELETE');
    });
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_rounded,
            size: 48, color: AppColors.error),
        title: const Text('Are you absolutely sure?'),
        content: const Text(
          'This action cannot be undone. All your tasks, attendance records, '
          'and social connections will be permanently deleted within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _deleting = true);
              final success = await ref
                  .read(authViewModelProvider.notifier)
                  .deleteAccount();
              if (mounted) {
                setState(() => _deleting = false);
                if (success) {
                  context.go('/auth/sign-in');
                } else {
                  final error = ref.read(authViewModelProvider).error;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Failed to delete account'),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Forever'),
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
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.delete_forever_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'This is permanent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
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
              'Type DELETE to confirm',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              enabled: !_deleting,
              decoration: InputDecoration(
                hintText: 'Type DELETE here',
                prefixIcon: const Icon(Icons.warning_amber_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 8),
            Text(
              _canDelete ? 'Confirmation matches' : 'Type "DELETE" exactly',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        _canDelete ? AppColors.success : AppColors.textTertiary,
                  ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _canDelete && !_deleting ? _confirmDelete : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  disabledBackgroundColor:
                      AppColors.error.withValues(alpha: 0.3),
                ),
                child: _deleting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete My Account'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
