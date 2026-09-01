import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/guest_session.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authViewModelProvider);
    final isGuest = authState.isGuest;
    final user = authState.user;
    final displayName =
        user?.displayName ?? (isGuest ? 'Guest' : 'SyncUp User');
    final username = user?.username ?? (isGuest ? 'local only' : 'syncup_user');

    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/notifications'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: NeoBrutalism.cardDecoration(isDark: isDark),
            child: Row(
              children: [
                UserAvatar(
                  seed: user?.id ?? displayName,
                  displayName: displayName,
                  size: 64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                      ),
                      if (user?.college != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.college!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isGuest)
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    onPressed: () => _showEditProfileDialog(context, ref),
                  ),
              ],
            ),
          ),

          if (isGuest) ...[
            const SizedBox(height: 16),
            _SignInPrompt(isDark: isDark),
          ],

          const SizedBox(height: 24),

          Text(
            'SETTINGS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 12),

          _ThemeToggleTile(isDark: isDark),

          // Privacy and notification preferences both write to the server, so
          // they are account-only.
          if (!isGuest) ...[
            _SettingsTile(
              icon: Icons.shield_rounded,
              iconColor: AppColors.accent,
              title: 'Privacy',
              subtitle: 'Search visibility and sharing preferences',
              onTap: () => context.go('/profile/privacy'),
            ),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              iconColor: AppColors.primary,
              title: 'Notification Preferences',
              subtitle: 'Manage reminders and alerts',
              onTap: () => context.go('/profile/notification-prefs'),
            ),
          ],

          const SizedBox(height: 24),
          Text(
            isGuest ? 'LOCAL DATA' : 'ACCOUNT',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 12),

          if (isGuest)
            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: 'Erase Local Data',
              subtitle: 'Delete everything stored on this device',
              onTap: () => _confirmEraseLocalData(context, ref),
            )
          else ...[
            _SettingsTile(
              icon: Icons.key_rounded,
              iconColor: AppColors.primary,
              title: 'Change Password',
              subtitle: 'Update your password and sign out other devices',
              onTap: () => context.go('/profile/change-password'),
            ),
            _SettingsTile(
              icon: Icons.devices_rounded,
              iconColor: AppColors.accent,
              title: 'Devices',
              subtitle: 'See where you are signed in and sign out remotely',
              onTap: () => context.go('/profile/devices'),
            ),
            _SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.warning,
              title: 'Log Out',
              subtitle: 'Sign out of your account',
              onTap: () => _confirmLogout(context, ref),
            ),
            _SettingsTile(
              icon: Icons.delete_forever_rounded,
              iconColor: AppColors.error,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              onTap: () => context.go('/profile/delete-account'),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmEraseLocalData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ERASE LOCAL DATA'),
        content: const Text(
          'This deletes every task and subject stored on this device. '
          'Because you have no account, this cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(guestSessionProvider.notifier).clear();
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go('/auth/sign-in');
            },
            child: const Text('ERASE'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('LOG OUT'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go('/auth/sign-in');
            },
            child: const Text('LOG OUT'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authViewModelProvider).user;
    final nameCtrl = TextEditingController(text: user?.displayName);
    final collegeCtrl = TextEditingController(text: user?.college);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('EDIT PROFILE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: collegeCtrl,
              decoration: const InputDecoration(
                labelText: 'College',
                prefixIcon: Icon(Icons.school_rounded),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              // Captured before any await: the dialog closes mid-flow, so
              // reaching for a context afterwards is unsafe.
              final messenger = ScaffoldMessenger.of(context);

              if (!ref.read(connectivityServiceProvider).isOnline) {
                if (ctx.mounted) Navigator.pop(ctx);
                showAppSnackBarOn(
                    messenger, 'You are offline. Connect to save.',
                    isError: true);
                return;
              }

              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                showAppSnackBarOn(messenger, 'Display name cannot be empty.',
                    isError: true);
                return;
              }

              final fields = <String, dynamic>{
                'display_name': name,
                // Sent even when blank so an entry can be cleared. Skipping
                // empty values meant college could be set but never unset.
                'college': collegeCtrl.text.trim(),
              };

              final saved = await ref
                  .read(authViewModelProvider.notifier)
                  .updateProfile(fields);

              // The result used to be discarded and the dialog popped either
              // way, so a rejected save looked identical to a successful one —
              // which is why editing appeared to do nothing.
              if (!saved) {
                showAppSnackBarOn(
                  messenger,
                  ref.read(authViewModelProvider).error ??
                      'Could not save. Try again.',
                  isError: true,
                );
                return;
              }

              if (ctx.mounted) Navigator.pop(ctx);
              showAppSnackBarOn(messenger, 'Profile updated');
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}

/// Shown to guests: explains what an account adds, and reassures them that the
/// work they have already done locally comes with them.
class _SignInPrompt extends StatelessWidget {
  final bool isDark;

  const _SignInPrompt({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(
        color: AppColors.accent,
        isDark: isDark,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USING SYNCUP LOCALLY',
            style: GoogleFonts.dmMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your tasks and attendance live on this device. Create an account '
            'to back them up, use the feed, and add friends.',
            style: GoogleFonts.archivo(
              fontSize: 13,
              height: 1.4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/auth/sign-up'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        'CREATE ACCOUNT',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/auth/sign-in'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        'SIGN IN',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleTile extends ConsumerWidget {
  final bool isDark;

  const _ThemeToggleTile({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).toggle(),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: NeoBrutalism.iconBoxDecoration(
                  color: mode == ThemeMode.dark
                      ? AppColors.warning
                      : AppColors.primaryDark,
                  isDark: isDark,
                ),
                child: Icon(
                  mode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      mode == ThemeMode.dark ? 'Dark mode' : 'Light mode',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: NeoBrutalism.chipDecoration(
                  color: mode == ThemeMode.dark
                      ? AppColors.warning
                      : AppColors.primary,
                  isDark: isDark,
                ),
                child: Text(
                  mode == ThemeMode.dark ? 'DARK' : 'LIGHT',
                  style: GoogleFonts.dmMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: mode == ThemeMode.dark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: NeoBrutalism.iconBoxDecoration(
                  color: iconColor,
                  isDark: isDark,
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(subtitle,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
