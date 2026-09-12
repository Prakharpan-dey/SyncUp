import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/di/notification_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../di/social_providers.dart';
import '../viewmodels/social_viewmodel.dart';

class GroupJoinScreen extends ConsumerStatefulWidget {
  final String token;
  const GroupJoinScreen({super.key, required this.token});

  @override
  ConsumerState<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends ConsumerState<GroupJoinScreen> {
  bool _loading = true;
  String? _error;

  /// True once the join is waiting for an admin rather than done.
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _joinGroup();
  }

  Future<void> _joinGroup() async {
    final result = await ref
        .read(socialRepositoryProvider)
        .joinGroup(widget.token, ref.read(currentUserIdProvider));
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (pending) => setState(() {
        _loading = false;
        _pending = pending;
      }),
    );
    // Waiting on an admin is exactly when a push saying "you're in" helps.
    if (_pending && mounted) {
      await ref
          .read(notificationPermissionHandlerProvider)
          .onFirstMeaningfulAction(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _loading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: NeoBrutalism.iconBoxDecoration(
                          color: _error != null
                              ? AppColors.error
                              : AppColors.success,
                          isDark: isDark,
                        ),
                        child: Icon(
                          _error != null
                              ? Icons.error_outline_rounded
                              : _pending
                                  ? Icons.hourglass_top_rounded
                                  : Icons.check_rounded,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _error != null
                            ? 'COULD NOT JOIN'
                            : _pending
                                ? 'REQUEST SENT'
                                : 'JOINED!',
                        style: GoogleFonts.bigShoulders(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ??
                            (_pending
                                ? "The group's admin will review your request. "
                                    "You'll get a notification when you're in."
                                : 'You have joined the group.'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.archivo(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () {
                          // The list may still be the one open from before the
                          // join; going back to it does not reload it.
                          ref
                              .read(socialViewModelProvider.notifier)
                              .loadGroups(ref.read(currentUserIdProvider));
                          context.go('/feed/groups');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: NeoBrutalism.cardDecoration(
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                          child: Text(
                            _error != null ? 'GO BACK' : 'VIEW GROUPS',
                            style: GoogleFonts.dmMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
