import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/notifications/push_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../tasks/di/task_providers.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  /// Keys as stored in `users.notification_settings`.
  static const _kTaskReminders = 'task_reminders';
  static const _kAttendanceWarnings = 'attendance_warnings';
  static const _kFriendRequests = 'friend_requests';
  static const _kReactions = 'reactions';

  late bool _taskReminders;
  late bool _attendanceWarnings;
  late bool _friendRequests;
  late bool _reactions;
  bool _saving = false;

  /// Null until read. Every switch below is inert unless this is authorized.
  AuthorizationStatus? _permission;

  @override
  void initState() {
    super.initState();

    // Seeded from the account rather than hardcoded to on, so the screen shows
    // what is actually saved. An absent key means enabled — see
    // User.notificationEnabled.
    final user = ref.read(authViewModelProvider).user;
    _taskReminders = user?.notificationEnabled(_kTaskReminders) ?? true;
    _attendanceWarnings = user?.notificationEnabled(_kAttendanceWarnings) ?? true;
    _friendRequests = user?.notificationEnabled(_kFriendRequests) ?? true;
    _reactions = user?.notificationEnabled(_kReactions) ?? true;
    // Off unless explicitly enabled: a daily 8am push is not something to
    // opt someone into by default.

    unawaited(_readPermission());
  }

  Future<void> _readPermission() async {
    final status = await ref.read(pushServiceProvider).permissionStatus();
    if (mounted) setState(() => _permission = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATION PREFERENCES'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_permission == AuthorizationStatus.denied) ...[
            _PermissionNotice(
              text: 'Notifications are turned off for SyncUp in your device '
                  'settings. These preferences will take effect once you turn '
                  'them back on.',
            ),
            const SizedBox(height: 16),
          ] else if (_permission == AuthorizationStatus.notDetermined) ...[
            _PermissionNotice(
              text: 'SyncUp has not asked for notification permission yet. '
                  'It will the first time you complete a task.',
            ),
            const SizedBox(height: 16),
          ],
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
      showAppSnackBar(context, 'You are offline. Connect to save.',
          isError: true);
      return;
    }

    setState(() => _saving = true);

    // One `notification_settings` object, not six top-level keys. The API
    // strips unknown fields, so the flat form arrived as {} and was rejected by
    // the "at least one field" guard — every save 422'd.
    final success =
        await ref.read(authViewModelProvider.notifier).updateProfile({
      'notification_settings': {
        _kTaskReminders: _taskReminders,
        _kAttendanceWarnings: _attendanceWarnings,
        _kFriendRequests: _friendRequests,
        _kReactions: _reactions,
      },
    });

    // Local task reminders are scheduled on the device and never pass through
    // the server's preference check, so switching the toggle off has to cancel
    // what is already pending rather than waiting for the next app open.
    if (success) {
      await ref.read(taskNotificationSchedulerProvider).sync(
            ref.read(taskViewModelProvider).tasks,
            remindersEnabled: _taskReminders,
          );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (!success) {
      // Stay put so the user can retry without re-toggling everything.
      showAppSnackBar(
        context,
        ref.read(authViewModelProvider).error ?? 'Could not save. Try again.',
        isError: true,
      );
      return;
    }

    // Entered with context.go(), which replaces the location rather
    // than pushing a route, so there is nothing on the stack to pop —
    // Navigator.pop() here was silently doing nothing.
    context.go('/profile');
    showAppSnackBar(context, 'Notification preferences saved');
  }
}

/// Explains that the switches below cannot take effect.
///
/// Without this the screen silently presents controls the OS is overriding,
/// which reads as the preferences not working.
class _PermissionNotice extends StatelessWidget {
  final String text;

  const _PermissionNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: NeoBrutalism.bannerDecoration(
        color: AppColors.warning,
        isDark: isDark,
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded,
              size: 20, color: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
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
