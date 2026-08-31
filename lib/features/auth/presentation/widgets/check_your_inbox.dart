import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';

/// Terminal state after an email has been sent.
///
/// Shared by the verification and password-reset flows, which otherwise
/// differ only in wording.
class CheckYourInbox extends StatelessWidget {
  final String email;
  final String message;
  final String doneLabel;
  final VoidCallback onDone;

  /// Optional secondary action, e.g. "Resend link".
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const CheckYourInbox({
    super.key,
    required this.email,
    required this.message,
    required this.onDone,
    this.doneLabel = 'BACK TO SIGN IN',
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: NeoBrutalism.iconBoxDecoration(
            color: AppColors.accent,
            isDark: isDark,
          ),
          child: const Icon(Icons.mark_email_unread_rounded,
              size: 32, color: Colors.black),
        ),
        const SizedBox(height: 24),
        Text('CHECK YOUR INBOX',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        if (email.isNotEmpty)
          Text(
            email,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(onPressed: onDone, child: Text(doneLabel)),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
        const Spacer(),
        Text(
          "Nothing yet? Check your spam folder — the link can take a minute.",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textTertiary,
              ),
        ),
      ],
    );
  }
}
