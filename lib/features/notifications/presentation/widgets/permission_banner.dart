import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../di/notification_providers.dart';

class PermissionBanner extends ConsumerStatefulWidget {
  const PermissionBanner({super.key});

  @override
  ConsumerState<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends ConsumerState<PermissionBanner> {
  bool _show = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final handler = ref.read(notificationPermissionHandlerProvider);
    final denied = await handler.wasPermissionDenied();
    if (mounted && denied && !_dismissed) {
      setState(() => _show = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: NeoBrutalism.bannerDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.06),
        isDark: isDark,
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enable notifications to get task reminders and social updates.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final handler = ref.read(notificationPermissionHandlerProvider);
              final granted = await handler.requestPermissionManually();
              if (granted && mounted) {
                setState(() => _show = false);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('ENABLE'),
          ),
          IconButton(
            onPressed: () => setState(() {
              _show = false;
              _dismissed = true;
            }),
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}
