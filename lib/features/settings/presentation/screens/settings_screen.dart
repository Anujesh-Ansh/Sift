import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.asData?.value?.id ?? 'Not authenticated';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Sync', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          _buildSectionHeader('User Identity & Security'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fingerprint, color: AppColors.primary),
              title: const Text('User ID', style: AppTypography.titleMedium),
              subtitle: Text(userId, style: AppTypography.bodyMedium),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionHeader('Synchronization & Storage'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync, color: AppColors.secondary),
                  title: const Text('Background Sync',
                      style: AppTypography.titleMedium),
                  subtitle: const Text('Every ~6 hours (WorkManager)',
                      style: AppTypography.bodyMedium),
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading:
                      Icon(Icons.storage_outlined, color: AppColors.warning),
                  title: Text('Storage Quota & Cache',
                      style: AppTypography.titleMedium),
                  subtitle: Text('Compressed thumbnails stored locally',
                      style: AppTypography.bodyMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionHeader('Intelligence Engine'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.psychology_outlined, color: AppColors.accent),
              title: Text('Gemini Multimodal Vision',
                  style: AppTypography.titleMedium),
              subtitle: Text('Model: gemini-1.5-flash (Structured Schema)',
                  style: AppTypography.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondaryDark,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
