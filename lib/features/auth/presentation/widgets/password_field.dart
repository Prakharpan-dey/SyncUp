import 'package:flutter/material.dart';

/// A password input with a visibility toggle.
///
/// Seven password fields across four screens each repeated `obscureText: true`
/// with no way to check what had been typed — which matters most on sign-up and
/// reset, where a typo is not discovered until the next sign-in fails.
///
/// Keeps the same `TextFormField` surface the auth forms already use, including
/// `errorText`, so per-field server errors on sign-up still render underneath.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;

  /// Server-reported error for this field, shown under the input.
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.validator,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: const Icon(Icons.lock_outlined),
        errorText: widget.errorText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          // Screen readers otherwise announce only "button".
          tooltip: _obscured ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}
