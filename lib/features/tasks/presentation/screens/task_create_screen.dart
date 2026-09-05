import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../notifications/di/notification_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../domain/entities/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/repeat_picker.dart';

class TaskCreateScreen extends ConsumerStatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  ConsumerState<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends ConsumerState<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  int? _dueMinutes;
  RepeatMode _repeat = RepeatMode.never;
  Set<int> _weekdays = const {};

  bool get _isRepeating => _repeat != RepeatMode.never;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final initial = _dueMinutes != null
        ? TimeOfDay(hour: _dueMinutes! ~/ 60, minute: _dueMinutes! % 60)
        : const TimeOfDay(hour: 9, minute: 0);
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _dueMinutes = picked.hour * 60 + picked.minute);
    }
  }

  Set<int> get _effectiveWeekdays =>
      _repeat == RepeatMode.daily ? {1, 2, 3, 4, 5, 6, 7} : _weekdays;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRepeating && _effectiveWeekdays.isEmpty) {
      setState(() {}); // surfaces the picker's own "pick at least one day"
      return;
    }

    final vm = ref.read(taskViewModelProvider.notifier);
    final userId = ref.read(currentUserIdProvider);
    final description = _descCtrl.text.isNotEmpty ? _descCtrl.text : null;

    if (_isRepeating) {
      final ok = await vm.submitNewSeries(
        userId: userId,
        title: _titleCtrl.text,
        description: description,
        weekdays: _effectiveWeekdays,
        dueMinutes: _dueMinutes,
        priority: _priority,
      );
      if (!ok) return;
    } else {
      await vm.submitNewTask(
        userId: userId,
        title: _titleCtrl.text,
        description: description,
        dueDate: _dueDate,
        priority: _priority,
        dueMinutes: _dueMinutes,
      );
    }

    if (!mounted) return;
    // Setting a time is itself the moment a reminder becomes meaningful, so ask
    // for permission here rather than waiting for the first completed task.
    if (_dueMinutes != null) {
      await ref
          .read(notificationPermissionHandlerProvider)
          .onFirstMeaningfulAction(context);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskState = ref.watch(taskViewModelProvider);
    final isLoading = taskState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('NEW TASK')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.length > 255) return 'Too long';
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),

              RepeatPicker(
                mode: _repeat,
                weekdays: _weekdays,
                enabled: !isLoading,
                onModeChanged: (m) => setState(() {
                  _repeat = m;
                  // Custom starts from today's weekday, so the common case of
                  // "this day every week" is one tap rather than eight.
                  if (m == RepeatMode.custom && _weekdays.isEmpty) {
                    _weekdays = {DateTime.now().weekday};
                  }
                }),
                onWeekdaysChanged: (d) => setState(() => _weekdays = d),
              ),
              const SizedBox(height: 16),

              // A repeating task gets its date from the rule, so offering a
              // single due date alongside it would be contradictory.
              if (!_isRepeating) ...[
                GestureDetector(
                  onTap: isLoading ? null : _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date (optional)',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'No date selected',
                      style: TextStyle(
                        color: _dueDate != null
                            ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              GestureDetector(
                onTap: isLoading ? null : _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Time (optional)',
                    prefixIcon: const Icon(Icons.schedule_rounded),
                    suffixIcon: _dueMinutes != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            tooltip: 'Clear time',
                            onPressed: isLoading
                                ? null
                                : () => setState(() => _dueMinutes = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _dueMinutes != null
                        ? '${DateHelpers.formatApiTime(_dueMinutes!)} — reminds you then'
                        : 'No time selected',
                    style: TextStyle(
                      color: _dueMinutes != null
                          ? (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'PRIORITY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(
                    value: TaskPriority.low,
                    label: Text('LOW'),
                    icon: Icon(Icons.arrow_downward_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: TaskPriority.medium,
                    label: Text('MED'),
                    icon: Icon(Icons.remove_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: TaskPriority.high,
                    label: Text('HIGH'),
                    icon: Icon(Icons.arrow_upward_rounded, size: 16),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: isLoading
                    ? null
                    : (s) => setState(() => _priority = s.first),
              ),

              if (taskState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: NeoBrutalism.bannerDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    isDark: isDark,
                  ),
                  child: Text(
                    taskState.error!,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isRepeating ? 'CREATE REPEATING TASK' : 'CREATE TASK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
