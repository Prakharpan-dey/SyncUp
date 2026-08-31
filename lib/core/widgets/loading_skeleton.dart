import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/neo_brutalism.dart';

class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
  });

  const LoadingSkeleton.card({super.key})
      : width = double.infinity,
        height = 80;

  const LoadingSkeleton.text({super.key, this.width = 120})
      : height = 14;

  const LoadingSkeleton.square({super.key, double size = 40})
      : width = size,
        height = size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class LoadingSkeletonList extends StatelessWidget {
  final int itemCount;
  const LoadingSkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
      child: Row(
        children: [
          const LoadingSkeleton.square(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeleton(height: 14, width: 160),
                const SizedBox(height: 8),
                LoadingSkeleton(
                  height: 10,
                  width: MediaQuery.of(context).size.width * 0.5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
