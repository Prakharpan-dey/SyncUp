import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late String _searchable;
  late String _sharing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _searchable = user?.privacySearchable ?? 'everyone';
    _sharing = user?.privacySharingDefault ?? 'summary';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRIVACY SETTINGS'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'WHO CAN FIND ME IN SEARCH?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 8),
          _RadioTile(
            value: 'everyone', groupValue: _searchable,
            label: 'Everyone', icon: Icons.public_rounded,
            onChanged: (v) => setState(() => _searchable = v),
          ),
          _RadioTile(
            value: 'friends', groupValue: _searchable,
            label: 'Friends only', icon: Icons.people_rounded,
            onChanged: (v) => setState(() => _searchable = v),
          ),
          _RadioTile(
            value: 'none', groupValue: _searchable,
            label: 'No one', icon: Icons.lock_rounded,
            onChanged: (v) => setState(() => _searchable = v),
          ),
          const SizedBox(height: 24),
          Text(
            'DEFAULT SHARING MODE',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 8),
          _RadioTile(
            value: 'none', groupValue: _sharing,
            label: 'Nothing', icon: Icons.visibility_off_rounded,
            onChanged: (v) => setState(() => _sharing = v),
          ),
          _RadioTile(
            value: 'summary', groupValue: _sharing,
            label: 'Summary stats only', icon: Icons.analytics_rounded,
            onChanged: (v) => setState(() => _sharing = v),
          ),
          _RadioTile(
            value: 'selected', groupValue: _sharing,
            label: 'Selected tasks', icon: Icons.checklist_rounded,
            onChanged: (v) => setState(() => _sharing = v),
          ),
          _RadioTile(
            value: 'all', groupValue: _sharing,
            label: 'All tasks', icon: Icons.visibility_rounded,
            onChanged: (v) => setState(() => _sharing = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SAVE CHANGES'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!ref.read(connectivityServiceProvider).isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are offline. Connect to save.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final success = await ref.read(authViewModelProvider.notifier).updateProfile({
      'privacy_searchable': _searchable,
      'privacy_sharing_default': _sharing,
    });
    setState(() => _saving = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Privacy settings saved'
              : 'Failed to save. Please try again.'),
        ),
      );
    }
  }
}

class _RadioTile extends StatelessWidget {
  final String value, groupValue, label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _RadioTile({
    required this.value, required this.groupValue, required this.label,
    required this.icon, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: selected
              ? NeoBrutalism.selectedDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  isDark: isDark,
                )
              : NeoBrutalism.unselectedDecoration(isDark: isDark),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.primary : null),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal)),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
