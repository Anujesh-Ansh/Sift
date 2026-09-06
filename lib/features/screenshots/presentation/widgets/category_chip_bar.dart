import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../infrastructure/ai/category_classifier.dart';
import '../../providers/screenshot_providers.dart';

class CategoryChipBar extends ConsumerWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final categories = ['All', ...CategoryClassifier.canonicalCategories];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return FilterChip(
            selected: isSelected,
            label: Text(
              category,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.textPrimaryDark
                    : AppColors.textSecondaryDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            backgroundColor: AppColors.darkSurfaceElevated,
            selectedColor: AppColors.primary.withValues(alpha: 0.25),
            checkmarkColor: AppColors.primary,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.darkBorder.withValues(alpha: 0.6),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            onSelected: (_) {
              ref.read(selectedCategoryFilterProvider.notifier).state =
                  category;
            },
          );
        },
      ),
    );
  }
}
