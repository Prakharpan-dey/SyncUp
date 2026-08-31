import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../viewmodels/attendance_viewmodel.dart';

class SubjectCreateScreen extends ConsumerStatefulWidget {
  const SubjectCreateScreen({super.key});

  @override
  ConsumerState<SubjectCreateScreen> createState() =>
      _SubjectCreateScreenState();
}

class _SubjectCreateScreenState extends ConsumerState<SubjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  double _thresholdPct = 75;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(attendanceViewModelProvider.notifier).addSubject(
          userId: ref.read(currentUserIdProvider),
          name: _nameCtrl.text,
          code: _codeCtrl.text.isEmpty ? null : _codeCtrl.text,
          thresholdPct: _thresholdPct.round(),
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(attendanceViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD SUBJECT'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'SUBJECT NAME',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Data Structures',
                prefixIcon: Icon(Icons.book_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Subject name is required';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),

            Text(
              'SUBJECT CODE (OPTIONAL)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. CS201',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),

            Text(
              'ATTENDANCE THRESHOLD',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Minimum attendance percentage required',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: NeoBrutalism.cardDecoration(isDark: isDark),
              child: Column(
                children: [
                  Text(
                    '${_thresholdPct.round()}%',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _thresholdPct,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${_thresholdPct.round()}%',
                      onChanged: (val) {
                        setState(() => _thresholdPct = val);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary,
                            ),
                      ),
                      Text(
                        '100%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: [50, 60, 75, 80, 85].map((pct) {
                final isSelected = _thresholdPct.round() == pct;
                return ActionChip(
                  label: Text('$pct%'),
                  backgroundColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : null,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: NeoBrutalism.borderWidthSmall,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : null,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onPressed: () {
                    setState(() => _thresholdPct = pct.toDouble());
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: NeoBrutalism.bannerDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  isDark: isDark,
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('CREATE SUBJECT'),
            ),
          ],
        ),
      ),
    );
  }
}
