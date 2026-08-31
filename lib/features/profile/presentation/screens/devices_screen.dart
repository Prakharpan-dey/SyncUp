import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../auth/di/auth_providers.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

/// Lists devices with a live session and lets the user end them.
///
/// Sessions survive token rotation, so each row is a device rather than a
/// credential — signing one out here does not disturb the others.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  List<AuthSession>? _sessions;
  String? _error;
  bool _loading = true;
  /// Session currently being revoked, so only that row shows a spinner.
  String? _revoking;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ref.read(authRepositoryProvider).getSessions();
    if (!mounted) return;

    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (sessions) => setState(() {
        _loading = false;
        _sessions = sessions;
      }),
    );
  }

  Future<void> _revoke(AuthSession session) async {
    if (!ref.read(connectivityServiceProvider).isOnline) {
      _snack('You are offline. Connect to sign out a device.');
      return;
    }

    setState(() => _revoking = session.sessionId);
    final result =
        await ref.read(authRepositoryProvider).revokeSession(session.sessionId);
    if (!mounted) return;
    setState(() => _revoking = null);

    result.fold(
      (f) => _snack(f.message),
      (_) {
        _snack('Device signed out.');
        _load();
      },
    );
  }

  Future<void> _confirmSignOutEverywhere() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SIGN OUT EVERYWHERE'),
        content: const Text(
          'Every device is signed out, including this one. '
          'You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SIGN OUT ALL'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(authRepositoryProvider).logoutAll();
    // The local session is cleared regardless of the server's answer, so send
    // them to sign-in either way rather than leaving a dead-looking app.
    await ref.read(authViewModelProvider.notifier).checkAuthStatus();
    if (mounted) context.go('/auth/sign-in');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('DEVICES')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(isDark),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.cloud_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(onPressed: _load, child: const Text('RETRY')),
          ),
        ],
      );
    }

    final sessions = _sessions ?? const <AuthSession>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Signing out a device ends its session immediately. Your other '
          'devices are unaffected.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
        for (final session in sessions) ...[
          _SessionCard(
            session: session,
            isDark: isDark,
            busy: _revoking == session.sessionId,
            onRevoke: session.isCurrent ? null : () => _revoke(session),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _revoking != null ? null : _confirmSignOutEverywhere,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('SIGN OUT EVERYWHERE'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final AuthSession session;
  final bool isDark;
  final bool busy;

  /// Null for the current device — it cannot sign itself out from this screen.
  final VoidCallback? onRevoke;

  const _SessionCard({
    required this.session,
    required this.isDark,
    required this.busy,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final label = session.deviceLabel ?? 'Unknown device';
    final when = DateFormat('d MMM yyyy, HH:mm').format(session.signedInAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.cardDecoration(isDark: isDark),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: NeoBrutalism.iconBoxDecoration(
              color: session.isCurrent ? AppColors.success : AppColors.primary,
              isDark: isDark,
            ),
            child: Icon(
              session.isCurrent
                  ? Icons.phone_android_rounded
                  : Icons.devices_rounded,
              size: 22,
              color: session.isCurrent ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (session.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          'THIS DEVICE',
                          style: GoogleFonts.dmMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Signed in $when',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onRevoke != null)
            busy
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Sign out this device',
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.error),
                    onPressed: onRevoke,
                  ),
        ],
      ),
    );
  }
}
