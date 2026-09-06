import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../categories/providers/category_providers.dart';
import '../../../screenshots/domain/entities/screenshot_item.dart';

class TriageCard extends ConsumerStatefulWidget {
  final ScreenshotItem item;
  final int currentIndex;
  final int totalCount;
  final Future<void> Function() onApprove;
  final Future<void> Function(
      String correctedCategory, List<String> tags, String? note) onCorrect;
  final VoidCallback onSkip;

  const TriageCard({
    super.key,
    required this.item,
    required this.currentIndex,
    required this.totalCount,
    required this.onApprove,
    required this.onCorrect,
    required this.onSkip,
  });

  @override
  ConsumerState<TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends ConsumerState<TriageCard> {
  late String _selectedCategory;
  late List<String> _tags;
  late TextEditingController _noteController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.item.primaryCategory;
    _tags = List.from(widget.item.tags);
    _noteController = TextEditingController(text: widget.item.userNote ?? '');
  }

  @override
  void didUpdateWidget(covariant TriageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _selectedCategory = widget.item.primaryCategory;
      _tags = List.from(widget.item.tags);
      _noteController.text = widget.item.userNote ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    setState(() => _isProcessing = true);
    try {
      if (_selectedCategory != widget.item.primaryCategory ||
          _noteController.text.trim().isNotEmpty) {
        await widget.onCorrect(
          _selectedCategory,
          _tags,
          _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      } else {
        await widget.onApprove();
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(allCategoriesProvider);
    final categories = {...allCategories, _selectedCategory}.toList();
    final isModified = _selectedCategory != widget.item.primaryCategory ||
        _noteController.text.trim() != (widget.item.userNote ?? '');

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        color: AppColors.success.withValues(alpha: 0.2),
        child:
            const Icon(Icons.check_circle, color: AppColors.success, size: 36),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.warning.withValues(alpha: 0.2),
        child: const Icon(Icons.skip_next, color: AppColors.warning, size: 36),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _handleApprove();
        } else {
          widget.onSkip();
        }
      },
      child: Card(
        margin: const EdgeInsets.all(AppSpacing.md),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
          side: BorderSide(
            color: AppColors.warning.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Queue position header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Text(
                      'Triage ${widget.currentIndex + 1} of ${widget.totalCount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline,
                            size: 12, color: AppColors.warning),
                        SizedBox(width: 4),
                        Text(
                          'Needs Review',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Image preview
              ClipRRect(
                borderRadius: AppSpacing.roundedMd,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  width: double.infinity,
                  color: AppColors.darkBackground,
                  child: Center(child: _buildImage()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                widget.item.title.isNotEmpty
                    ? widget.item.title
                    : 'Untitled Screenshot',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Category Selector
              Text(
                'CATEGORY CLASSIFICATION',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSelected = _selectedCategory == cat;
                    final isDelete = cat == 'Delete';

                    return ChoiceChip(
                      selected: isSelected,
                      avatar: isDelete
                          ? Icon(
                              Icons.delete_outline,
                              size: 13,
                              color: isSelected ? Colors.white : AppColors.error,
                            )
                          : null,
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white
                              : (isDelete
                                  ? AppColors.error
                                  : AppColors.textSecondaryDark),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selectedColor: isDelete ? AppColors.error : AppColors.primary,
                      backgroundColor: isDelete
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.darkSurfaceElevated,
                      side: isDelete
                          ? BorderSide(
                              color: isSelected
                                  ? AppColors.error
                                  : AppColors.error.withValues(alpha: 0.4),
                            )
                          : null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    );
                  },
                ),
              ),
              if (_selectedCategory == 'Delete') ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedSm,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_delete_outlined,
                          size: 14, color: AppColors.error),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Will be scheduled to auto-delete in 30 days.',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // Extracted Text snippet
              if (widget.item.extractedText.isNotEmpty) ...[
                Text(
                  'DETECTED OCR TEXT',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: Text(
                    widget.item.extractedText,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // User note
              Text(
                'ADD CONTEXT / NOTE',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _noteController,
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'e.g., Save for weekend renovation project',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: const Text('Skip'),
                      onPressed: _isProcessing ? null : widget.onSkip,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isModified ? AppColors.primary : AppColors.success,
                      ),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              isModified
                                  ? Icons.check
                                  : Icons.check_circle_outline,
                              size: 18),
                      label:
                          Text(isModified ? 'Confirm Changes' : 'Approve AI'),
                      onPressed: _isProcessing ? null : _handleApprove,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.item.localThumbnailPath != null &&
        widget.item.localThumbnailPath!.isNotEmpty) {
      final file = File(widget.item.localThumbnailPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    }
    return const Icon(Icons.photo_outlined,
        size: 48, color: AppColors.textTertiaryDark);
  }
}
