import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: AppSpacing.roundedSm,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Project Sift', style: AppTypography.displayMedium),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined),
            tooltip: 'Review Queue',
            onPressed: () => Navigator.pushNamed(context, '/review'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: AppSpacing.paddingXl,
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Screenshot Intelligence',
                style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Discovering and organizing device screenshots...',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
