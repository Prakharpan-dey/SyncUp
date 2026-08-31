import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool _taskReminders = true;
  bool _attendanceWarnings = true;
  bool _friendRequests = true;
  bool _reactions = true;
  bool _comments = true;
  bool _dailyDigest = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATION PREFERENCES'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'REMINDERS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.alarm_rounded,
            iconColor: AppColors.primary,
            title: 'Task Reminders',
            subtitle: 'Before tasks are due',
            value: _taskReminders,
            onChanged: (v) => setState(() => _taskReminders = v),
          ),
          _ToggleTile(
            icon: Icons.warning_amber_rounded,
            iconColor: AppColors.warning,
            title: 'Attendance Warnings',
            subtitle: 'When below your threshold',
            value: _attendanceWarnings,
            onChanged: (v) => setState(() => _attendanceWarnings = v),
          ),
          const SizedBox(height: 20),
          Text(
            'SOCIAL',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.person_add_rounded,
            iconColor: AppColors.accent,
            title: 'Friend Requests',
            subtitle: 'When someone sends a request',
            value: _friendRequests,
            onChanged: (v) => setState(() => _friendRequests = v),
          ),
          _ToggleTile(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.error,
            title: 'Reactions',
            subtitle: 'When someone reacts to your progress',
            value: _reactions,
            onChanged: (v) => setState(() => _reactions = v),
          ),
          _ToggleTile(
            icon: Icons.chat_bubble_rounded,
            iconColor: AppColors.info,
            title: 'Comments',
            subtitle: 'When someone comments on your post',
            value: _comments,
            onChanged: (v) => setState(() => _comments = v),
          ),
          const SizedBox(height: 20),
          Text(
            'DIGEST',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.summarize_rounded,
            iconColor: AppColors.success,
            title: 'Daily Digest',
            subtitle: 'Summary at 8 AM — tasks due & attendance',
            value: _dailyDigest,
            onChanged: (v) => setState(() => _dailyDigest = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE CHANGES'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!ref.read(connectivityServiceProvider).isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are offline. Connect to save.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final success = await ref.read(authViewModelProvider.notifier).updateProfile({
      'notification_task_reminders': _taskReminders,
      'notification_attendance_warnings': _attendanceWarnings,
      'notification_friend_requests': _friendRequests,
      'notification_reactions': _reactions,
      'notification_comments': _comments,
      'notification_daily_digest': _dailyDigest,
    });
    setState(() => _saving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Notification preferences saved'
              : 'Failed to save. Please try again.'),
        ),
      );
    }
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: NeoBrutalism.iconBoxDecoration(
                color: iconColor,
                isDark: isDark,
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary)),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
