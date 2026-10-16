import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../domain/entities/report_reason.dart';
import '../viewmodels/social_viewmodel.dart';

enum _SafetyAction { report, block }

/// Report or block someone, from anywhere their name or posts appear.
///
/// Pass [feedItemId] when it is opened from a post: the report is then about
/// that post rather than the person in general. Play requires both actions in
/// any app where people see each other's content.
Future<void> showUserSafetySheet(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
  String? feedItemId,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  final action = await showModalBottomSheet<_SafetyAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(feedItemId != null ? 'Report this post' : 'Report $name'),
            onTap: () => Navigator.pop(ctx, _SafetyAction.report),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: AppColors.error),
            title: Text('Block $name',
                style: const TextStyle(color: AppColors.error)),
            onTap: () => Navigator.pop(ctx, _SafetyAction.block),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;

  final social = ref.read(socialViewModelProvider.notifier);

  switch (action) {
    case _SafetyAction.report:
      final filed = await showModalBottomSheet<(ReportReason, String)>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ReportSheet(name: name, isPost: feedItemId != null),
      );
      if (filed == null) return;
      final ok = await social.report(
        userId: userId,
        feedItemId: feedItemId,
        reason: filed.$1,
        details: filed.$2,
      );
      showAppSnackBarOn(
        messenger,
        ok
            ? "Thanks for reporting. We'll review it."
            : ref.read(socialViewModelProvider).error ?? 'Could not send the report',
        isError: !ok,
      );

    case _SafetyAction.block:
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('BLOCK ${name.toUpperCase()}?'),
          content: Text(
            "You'll stop being friends, and neither of you will see the "
            "other's posts or find each other in search. $name isn't told. "
            'You can unblock them from Profile → Blocked users.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('BLOCK'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final ok = await social.blockUser(userId);
      showAppSnackBarOn(
        messenger,
        ok ? 'Blocked $name' : ref.read(socialViewModelProvider).error ?? 'Could not block',
        isError: !ok,
      );
  }
}

/// Picks a reason and an optional note. Pops `(reason, details)`.
class ReportSheet extends StatefulWidget {
  final String name;
  final bool isPost;

  const ReportSheet({super.key, required this.name, required this.isPost});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isPost ? 'REPORT THIS POST' : 'REPORT ${widget.name.toUpperCase()}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              "What's wrong? Reports are private. ${widget.name} isn't told who sent it.",
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (r) => setState(() => _reason = r),
              child: Column(
                children: [
                  for (final r in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: r,
                      title: Text(r.label),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _details,
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Anything else we should know (optional)',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _reason == null
                  ? null
                  : () => Navigator.pop(context, (_reason!, _details.text)),
              child: const Text('SEND REPORT'),
            ),
          ],
        ),
      ),
    );
  }
}
