import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../di/task_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_series.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/repeat_picker.dart';

/// Edits the rule behind a repeating task.
///
/// Changes apply to occurrences from today onwards. Anything already completed,
/// and any day already past, is left alone — the point of keeping missed days
/// is that the record stays honest.
class TaskSeriesEditScreen extends ConsumerStatefulWidget {
  final String seriesId;
  const TaskSeriesEditScreen({super.key, required this.seriesId});

  @override
  ConsumerState<TaskSeriesEditScreen> createState() =>
      _TaskSeriesEditScreenState();
}

class _TaskSeriesEditScreenState extends ConsumerState<TaskSeriesEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();

  TaskSeries? _series;
  bool _loading = true;
  bool _saving = false;

  TaskPriority _priority = TaskPriority.medium;
  Set<int> _weekdays = const {};
  int? _dueMinutes;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    final result =
        await ref.read(taskSeriesRepositoryProvider).getSeries(userId);
    final all = result.getOrElse((_) => const <TaskSeries>[]);
    final found = all.where((s) => s.id == widget.seriesId).firstOrNull;

    if (!mounted) return;
    setState(() {
      _series = found;
      _loading = false;
      if (found != null) {
        _titleCtrl.text = found.title;
        _priority = found.priority;
        _weekdays = found.weekdays;
        _dueMinutes = found.dueMinutes;
      }
    });
  }

  RepeatMode get _mode =>
      _weekdays.length == 7 ? RepeatMode.daily : RepeatMode.custom;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      setState(() {});
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(taskViewModelProvider.notifier).saveSeries(
          _series!.copyWith(
            title: _titleCtrl.text.trim(),
            priority: _priority,
            weekdays: _weekdays,
            dueMinutes: _dueMinutes,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);

    showAppSnackBarOn(
      messenger,
      ok ? 'Repeating task updated' : 'Could not save. Please try again.',
      isError: !ok,
    );
    if (ok) context.pop();
  }

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('STOP REPEATING'),
        content: const Text(
          'Future occurrences will be removed. Days you already completed, and '
          'any day already past, are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('STOP'),
          ),
        ],
      ),
    );
    if (stop != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(taskViewModelProvider.notifier).stopSeries(_series!);
    if (!mounted) return;
    showAppSnackBarOn(messenger, 'Repeating task stopped');
    // Back to the list, not back one screen: this screen is reached from the
    // detail of a future occurrence, and stopping has just deleted it, so a
    // plain pop would land on "Task not found".
    context.go('/tasks');
  }

  /// Unlike stopping, nothing of the rule is kept: every pending day goes,
  /// missed past ones included. Completed days stay as ordinary tasks.
  Future<void> _confirmDelete() async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE REPEATING TASK'),
        content: const Text(
          'Removes the repeating rule and every day not yet completed, missed '
          'ones included. Days you completed stay in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (delete != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(taskViewModelProvider.notifier)
        .deleteSeriesPermanently(_series!.id, _series!.userId);
    if (!mounted) return;
    showAppSnackBarOn(messenger, 'Repeating task deleted');
    context.go('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('EDIT REPEAT')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EDIT REPEAT')),
        body: const Center(child: Text('Repeating task not found')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('EDIT REPEAT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Changes apply from today onwards. Days you have already '
                'completed stay as they are.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_saving,
              ),
              const SizedBox(height: 16),

              RepeatPicker(
                mode: _mode,
                weekdays: _weekdays,
                enabled: !_saving,
                allowNever: false,
                onModeChanged: (m) => setState(() {
                  _weekdays = m == RepeatMode.daily
                      ? {1, 2, 3, 4, 5, 6, 7}
                      : {DateTime.now().weekday};
                }),
                onWeekdaysChanged: (d) => setState(() => _weekdays = d),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _saving ? null : _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Time (optional)',
                    prefixIcon: const Icon(Icons.schedule_rounded),
                    suffixIcon: _dueMinutes != null
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            tooltip: 'Clear time',
                            onPressed: _saving
                                ? null
                                : () => setState(() => _dueMinutes = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _dueMinutes != null
                        ? DateHelpers.formatApiTime(_dueMinutes!)
                        : 'No time selected',
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
                  ButtonSegment(value: TaskPriority.low, label: Text('LOW')),
                  ButtonSegment(value: TaskPriority.medium, label: Text('MED')),
                  ButtonSegment(value: TaskPriority.high, label: Text('HIGH')),
                ],
                selected: {_priority},
                onSelectionChanged:
                    _saving ? null : (s) => setState(() => _priority = s.first),
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('SAVE CHANGES'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _saving ? null : _confirmStop,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('STOP REPEATING'),
              ),
              TextButton(
                onPressed: _saving ? null : _confirmDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('DELETE REPEATING TASK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
