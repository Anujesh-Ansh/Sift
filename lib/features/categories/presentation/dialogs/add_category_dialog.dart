import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../providers/category_providers.dart';

/// Displays a modal dialog allowing the user to create a new custom category.
Future<String?> showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  String? errorMessage;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.category_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('New Category', style: AppTypography.titleMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a custom category to organize and filter your screenshots.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTypography.bodyMedium,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Travel, Gym, Coding, Tax',
                  errorText: errorMessage,
                  filled: true,
                  fillColor: AppColors.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onSubmitted: (_) async {
                  final error = await ref
                      .read(customCategoriesProvider.notifier)
                      .addCategory(controller.text);
                  if (error != null) {
                    setState(() => errorMessage = error);
                  } else if (ctx.mounted) {
                    Navigator.pop(ctx, controller.text.trim());
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondaryDark)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              onPressed: () async {
                final error = await ref
                    .read(customCategoriesProvider.notifier)
                    .addCategory(controller.text);
                if (error != null) {
                  setState(() => errorMessage = error);
                } else if (ctx.mounted) {
                  Navigator.pop(ctx, controller.text.trim());
                }
              },
              child: const Text('Add Category'),
            ),
          ],
        );
      },
    ),
  );
}
