import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class PrivacySetupScreen extends ConsumerStatefulWidget {
  const PrivacySetupScreen({super.key});

  @override
  ConsumerState<PrivacySetupScreen> createState() => _PrivacySetupScreenState();
}

class _PrivacySetupScreenState extends ConsumerState<PrivacySetupScreen> {
  String _searchable = 'everyone';
  String _sharing = 'summary';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: NeoBrutalism.iconBoxDecoration(
                  color: AppColors.accent,
                  isDark: isDark,
                ),
                child: const Icon(Icons.shield_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                'YOUR PRIVACY, YOUR RULES',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              Text(
                'You can change these anytime in Settings.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Who can find me
              Text(
                'WHO CAN FIND ME IN SEARCH?',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              _buildOption('everyone', 'Everyone', Icons.public_rounded,
                  _searchable, (v) => setState(() => _searchable = v)),
              _buildOption(
                  'friends',
                  'Friends only',
                  Icons.people_rounded,
                  _searchable,
                  (v) => setState(() => _searchable = v)),
              _buildOption(
                  'none',
                  'No one',
                  Icons.lock_rounded,
                  _searchable,
                  (v) => setState(() => _searchable = v)),

              const SizedBox(height: 24),

              // Default sharing
              Text(
                'WHAT DO I SHARE WITH FRIENDS?',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              _buildOption(
                  'none',
                  'Nothing',
                  Icons.visibility_off_rounded,
                  _sharing,
                  (v) => setState(() => _sharing = v)),
              _buildOption(
                  'summary',
                  'Summary stats only (recommended)',
                  Icons.analytics_rounded,
                  _sharing,
                  (v) => setState(() => _sharing = v)),
              _buildOption(
                  'all',
                  'Everything including task titles',
                  Icons.visibility_rounded,
                  _sharing,
                  (v) => setState(() => _sharing = v)),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _onGetStarted,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('GET STARTED'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onGetStarted() async {
    if (!ref.read(connectivityServiceProvider).isOnline) {
      if (mounted) {
        showAppSnackBar(context, 'You are offline. Connect to continue.',
            isError: true);
      }
      return;
    }
    setState(() => _saving = true);
    await ref.read(authViewModelProvider.notifier).updateProfile({
      'privacy_searchable': _searchable,
      'privacy_sharing_default': _sharing,
    });
    setState(() => _saving = false);
    if (mounted) context.go('/home');
  }

  Widget _buildOption(String value, String label, IconData icon,
      String groupValue, ValueChanged<String> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = value == groupValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: selected
              ? NeoBrutalism.selectedDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  isDark: isDark,
                )
              : NeoBrutalism.unselectedDecoration(isDark: isDark),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? AppColors.primary : null,
                      ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
