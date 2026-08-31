import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../viewmodels/social_viewmodel.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(socialViewModelProvider.notifier)
          .loadGroups(ref.read(currentUserIdProvider));
    });
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CREATE GROUP'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Group name',
            prefixIcon: Icon(Icons.group_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                ref.read(socialViewModelProvider.notifier).createGroup(
                      name: nameCtrl.text.trim(),
                      createdBy: ref.read(currentUserIdProvider),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GROUPS'),
      ),
      body: state.isLoading && state.groups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.groups.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: state.groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = state.groups[index];
                    return GestureDetector(
                      onTap: () => context.go('/feed/groups/${group.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration:
                            NeoBrutalism.cardDecoration(isDark: isDark),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: NeoBrutalism.iconBoxDecoration(
                                color: AppColors.accent,
                                isDark: isDark,
                              ),
                              child: const Icon(
                                Icons.group_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('NEW GROUP'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: NeoBrutalism.iconBoxDecoration(
                color: AppColors.accent,
                isDark: isDark,
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO GROUPS YET',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a group to share\nprogress with your classmates.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
