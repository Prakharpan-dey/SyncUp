import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class DisplayNameScreen extends ConsumerStatefulWidget {
  const DisplayNameScreen({super.key});

  @override
  ConsumerState<DisplayNameScreen> createState() => _DisplayNameScreenState();
}

class _DisplayNameScreenState extends ConsumerState<DisplayNameScreen> {
  final _nameCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _collegeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                Text(
                  'What should we call you?',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is how your friends will see you on SyncUp.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),

                // Display name (required)
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display Name *',
                    hintText: 'e.g. Prakhar Pandey',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Display name is required';
                    }
                    if (v.trim().length > 80) {
                      return 'Must be 80 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // College (optional)
                TextFormField(
                  controller: _collegeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'College (optional)',
                    hintText: 'e.g. IIT Delhi',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                Text(
                  'College is optional and helps friends find you.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textTertiary,
                      ),
                ),

                const Spacer(),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _onContinue,
                    child: _saving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (!ref.read(connectivityServiceProvider).isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are offline. Connect to continue.')),
        );
      }
      return;
    }

    setState(() => _saving = true);
    final fields = <String, dynamic>{
      'display_name': _nameCtrl.text.trim(),
    };
    if (_collegeCtrl.text.trim().isNotEmpty) {
      fields['college'] = _collegeCtrl.text.trim();
    }
    await ref.read(authViewModelProvider.notifier).updateProfile(fields);
    setState(() => _saving = false);
    if (mounted) context.go('/onboarding/privacy');
  }
}
