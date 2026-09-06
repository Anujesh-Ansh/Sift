import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../providers/gemini_providers.dart';
import '../../providers/ingestion_providers.dart';
import '../../providers/screenshot_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/processing_indicator_banner.dart';
import '../widgets/screenshot_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoDeletionServiceProvider).purgeExpiredScreenshots().ignore();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _triggerSync() async {
    ref.read(autoDeletionServiceProvider).purgeExpiredScreenshots().ignore();
    final apiKey = ref.read(geminiApiKeyProvider);
    if (apiKey.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tip: Set your Gemini API key in Settings so AI can categorize images!',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.black,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ),
      );
    }

    final syncService = ref.read(deltaSyncServiceProvider);
    final count = await syncService.syncNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Discovered $count new screenshot${count > 1 ? 's' : ''}!'
              : 'Device screenshots up to date.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenshotsAsync = ref.watch(filteredScreenshotsProvider);
    final reviewQueueAsync = ref.watch(reviewQueueStreamProvider);
    final pendingReviewCount = reviewQueueAsync.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Search title, category, tags, OCR text...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              )
            : Row(
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
                  const Text('Project Sift',
                      style: AppTypography.displayMedium),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                  _isSearching = false;
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          // Review Queue button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.rate_review_outlined),
                tooltip: 'Review Queue',
                onPressed: () => Navigator.pushNamed(context, AppRouter.review),
              ),
              if (pendingReviewCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$pendingReviewCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _triggerSync,
        child: Column(
          children: [
            const ProcessingIndicatorBanner(),
            const SizedBox(height: AppSpacing.xs),
            const CategoryChipBar(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: screenshotsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ScreenshotCard(
                          item: item,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.screenshotDetail,
                              arguments: item,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text('Error loading library: $e',
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton.tonal(
                          onPressed: () =>
                              ref.invalidate(screenshotsStreamProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _triggerSync,
        icon: const Icon(Icons.sync),
        label: const Text('Sync Media'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    final category = ref.watch(selectedCategoryFilterProvider);
    final isCategoryFiltered = category != 'All';

    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
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
                child: Icon(
                  isCategoryFiltered
                      ? Icons.filter_alt_off_outlined
                      : Icons.photo_library_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isCategoryFiltered
                    ? 'No "$category" Screenshots'
                    : 'No Screenshots Found',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  isCategoryFiltered
                      ? 'No screenshots have been classified as "$category" yet. Try viewing All or switch categories.'
                      : 'Tap "Sync Media" below or grant photo permissions in Settings to organize screenshots.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isCategoryFiltered)
                FilledButton.icon(
                  onPressed: () {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        'All';
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Show All Screenshots'),
                )
              else
                FilledButton.icon(
                  onPressed: _triggerSync,
                  icon: const Icon(Icons.sync),
                  label: const Text('Scan Device Now'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
