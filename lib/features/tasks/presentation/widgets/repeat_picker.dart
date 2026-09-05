import 'package:flutter/material.dart';

/// How often a task repeats.
///
/// Only the modes the product actually supports. "Daily" is not a distinct rule
/// underneath — it is stored as all seven weekdays — but it is worth its own
/// button because it is what most repeating tasks are.
enum RepeatMode { never, daily, custom }

/// Picks a repeat rule: never, every day, or chosen days of the week.
class RepeatPicker extends StatelessWidget {
  final RepeatMode mode;
  final Set<int> weekdays;
  final ValueChanged<RepeatMode> onModeChanged;
  final ValueChanged<Set<int>> onWeekdaysChanged;
  final bool enabled;

  /// Whether "never" is offered.
  ///
  /// False when editing an existing repeating task: turning repetition off
  /// there is a destructive change to future occurrences, so it goes through an
  /// explicit "stop repeating" action with its own confirmation rather than a
  /// segment that looks like any other.
  final bool allowNever;

  const RepeatPicker({
    super.key,
    required this.mode,
    required this.weekdays,
    required this.onModeChanged,
    required this.onWeekdaysChanged,
    this.enabled = true,
    this.allowNever = true,
  });

  /// Monday-first, matching `DateTime.weekday` (Mon = 1) and how a week reads
  /// in the rest of the app.
  static const _labels = <int, String>{
    DateTime.monday: 'M',
    DateTime.tuesday: 'T',
    DateTime.wednesday: 'W',
    DateTime.thursday: 'T',
    DateTime.friday: 'F',
    DateTime.saturday: 'S',
    DateTime.sunday: 'S',
  };

  static const _names = <int, String>{
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'REPEATS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<RepeatMode>(
          segments: [
            if (allowNever)
              const ButtonSegment(value: RepeatMode.never, label: Text('NEVER')),
            const ButtonSegment(value: RepeatMode.daily, label: Text('DAILY')),
            const ButtonSegment(value: RepeatMode.custom, label: Text('CUSTOM')),
          ],
          selected: {mode},
          onSelectionChanged:
              enabled ? (s) => onModeChanged(s.first) : null,
        ),
        if (mode == RepeatMode.custom) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final day in _labels.keys)
                FilterChip(
                  // The label alone is ambiguous — two Ts and two Ss — so the
                  // full day name goes to screen readers.
                  label: Text(_labels[day]!, semanticsLabel: _names[day]),
                  selected: weekdays.contains(day),
                  onSelected: enabled
                      ? (selected) {
                          final next = Set<int>.from(weekdays);
                          if (selected) {
                            next.add(day);
                          } else {
                            next.remove(day);
                          }
                          onWeekdaysChanged(next);
                        }
                      : null,
                ),
            ],
          ),
          if (weekdays.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Pick at least one day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ],
    );
  }
}
