import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../categories/presentation/dialogs/add_category_dialog.dart';
import '../../../categories/providers/category_providers.dart';
import '../../providers/screenshot_providers.dart';

class CategoryChipBar extends ConsumerWidget {
  const CategoryChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final allCategories = ref.watch(allCategoriesProvider);
    final categories = ['All', ...allCategories];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length + 1, // +1 for "+ Add" chip
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            // "+ Add" button
            return ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              label: Text(
                'Add',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              onPressed: () async {
                final created = await showAddCategoryDialog(context, ref);
                if (created != null) {
                  ref.read(selectedCategoryFilterProvider.notifier).state = created;
                }
              },
            );
          }

          final category = categories[index];
          final isSelected = selectedCategory == category;
          final isDelete = category == 'Delete';

          return FilterChip(
            selected: isSelected,
            avatar: isDelete
                ? Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: isSelected ? AppColors.error : AppColors.error.withValues(alpha: 0.7),
                  )
                : null,
            label: Text(
              category,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? (isDelete ? AppColors.error : AppColors.textPrimaryDark)
                    : (isDelete ? AppColors.error.withValues(alpha: 0.8) : AppColors.textSecondaryDark),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            backgroundColor: isDelete
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.darkSurfaceElevated,
            selectedColor: isDelete
                ? AppColors.error.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.25),
            checkmarkColor: isDelete ? AppColors.error : AppColors.primary,
            showCheckmark: false,
            side: BorderSide(
              color: isSelected
                  ? (isDelete ? AppColors.error : AppColors.primary)
                  : (isDelete
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.darkBorder.withValues(alpha: 0.6)),
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
