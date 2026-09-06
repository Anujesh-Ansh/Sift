import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../screenshots/providers/gemini_providers.dart';
import '../../../screenshots/providers/ingestion_providers.dart';
import '../../../screenshots/providers/screenshot_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: ref.read(geminiApiKeyProvider),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await ref.read(geminiApiKeyProvider.notifier).setApiKey(key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API key saved & persisted to device!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _reanalyzeAll() async {
    final apiKey = ref.read(geminiApiKeyProvider);
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter and save your Gemini API Key first!'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ref.read(deduplicationServiceProvider).clear();
    final count = await ref.read(deltaSyncServiceProvider).syncNow();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Re-analyzing $count screenshots with Gemini 2.5 Vision...'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _reconcileDeleted() async {
    final user = ref.read(currentUserIdProvider) ?? 'anonymous';
    final service = ref.read(deletionReconciliationServiceProvider);
    final count = await service.reconcileDeletedAssets(userId: user);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Reconciliation complete. Cleaned up $count purged assets.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    final permService = ref.read(mediaPermissionServiceProvider);
    final state = await permService.requestPermission();
    final granted = state.hasAccess;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? 'Photo permission granted!'
              : 'Permission denied or limited.'),
          backgroundColor: granted ? AppColors.success : AppColors.warning,
        ),
      );
      ref.invalidate(mediaPermissionStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userId = authState.asData?.value?.id ?? 'Not authenticated';
    final permissionAsync = ref.watch(mediaPermissionStatusProvider);

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
          _buildSectionHeader('Media Permissions'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text('Storage / Photo Library',
                  style: AppTypography.titleMedium),
              subtitle: Text(
                'Status: ${permissionAsync.value?.name ?? 'checking...'}',
                style: AppTypography.bodyMedium,
              ),
              trailing: TextButton(
                onPressed: _requestPermissions,
                child: const Text('Grant'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionHeader('Intelligence Engine & Gemini API'),
          Card(
            child: Padding(
              padding: AppSpacing.paddingMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.psychology_outlined,
                        color: AppColors.accent),
                    title: Text('Gemini Multimodal Vision',
                        style: AppTypography.titleMedium),
                    subtitle: Text('Model: gemini-2.5-flash (Structured JSON)',
                        style: AppTypography.bodyMedium),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'API Key (Overrides compile-time key & persists to device)',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _apiKeyController,
                          obscureText: _isObscured,
                          decoration: InputDecoration(
                            hintText: 'Enter AI Studio Gemini API Key...',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _isObscured = !_isObscured),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _saveApiKey,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(builder: (context) {
                    final key = ref.watch(geminiApiKeyProvider);
                    if (key.isNotEmpty) {
                      return Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Active & Saved (${key.substring(0, (key.length > 8 ? 8 : key.length))}...)',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'No API Key Set! Screenshots will fall back to Review.',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionHeader('Synchronization & Maintenance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.auto_awesome, color: AppColors.primary),
                  title: const Text('Re-analyze All with AI',
                      style: AppTypography.titleMedium),
                  subtitle: const Text(
                      'Clear cache and run Gemini 2.5 on all device screenshots',
                      style: AppTypography.bodyMedium),
                  onTap: _reanalyzeAll,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.sync, color: AppColors.secondary),
                  title: const Text('Background Sync',
                      style: AppTypography.titleMedium),
                  subtitle: const Text('Periodic schedule (~6 hours)',
                      style: AppTypography.bodyMedium),
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {},
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined,
                      color: AppColors.warning),
                  title: const Text('Reconcile Deleted Media',
                      style: AppTypography.titleMedium),
                  subtitle: const Text(
                      'Purge cloud indexing for deleted device screenshots',
                      style: AppTypography.bodyMedium),
                  onTap: _reconcileDeleted,
                ),
              ],
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
