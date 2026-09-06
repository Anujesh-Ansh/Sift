import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../categories/presentation/dialogs/add_category_dialog.dart';
import '../../../categories/providers/category_providers.dart';
import '../../domain/entities/processing_status.dart';
import '../../domain/entities/screenshot_item.dart';
import '../../providers/screenshot_providers.dart';

class ScreenshotDetailScreen extends ConsumerStatefulWidget {
  final ScreenshotItem item;

  const ScreenshotDetailScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<ScreenshotDetailScreen> createState() =>
      _ScreenshotDetailScreenState();
}

class _ScreenshotDetailScreenState
    extends ConsumerState<ScreenshotDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _tagInputController;
  late String _selectedCategory;
  late List<String> _tags;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _noteController = TextEditingController(text: widget.item.userNote ?? '');
    _tagInputController = TextEditingController();
    _selectedCategory = widget.item.primaryCategory;
    _tags = List.from(widget.item.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(screenshotRepositoryProvider);
      final isCategoryCorrected =
          _selectedCategory != widget.item.primaryCategory;

      final scheduledDate = _selectedCategory == 'Delete'
          ? (widget.item.scheduledDeletionDate ??
              DateTime.now().add(const Duration(days: 30)))
          : null;

      final updatedItem = widget.item.copyWith(
        title: _titleController.text.trim(),
        primaryCategory: _selectedCategory,
        tags: _tags,
        userNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        scheduledDeletionDate: scheduledDate,
        clearScheduledDeletionDate: _selectedCategory != 'Delete',
        reviewStatus: isCategoryCorrected
            ? ReviewStatus.corrected
            : ReviewStatus.approved,
        needsHumanContext: false,
        updatedAt: DateTime.now(),
      );

      await repo.saveScreenshot(updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _restoreFromDelete() async {
    setState(() => _isSaving = true);
    try {
      final autoDel = ref.read(autoDeletionServiceProvider);
      await autoDel.restoreItem(widget.item, targetCategory: 'Uncategorized');
      setState(() => _selectedCategory = 'Uncategorized');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restored from Delete bucket!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _permanentDeleteNow() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceElevated,
        title: const Text('Permanent Deletion'),
        content: const Text(
          'Are you sure you want to permanently delete this screenshot now? This will remove it from your device gallery and cloud storage immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final autoDel = ref.read(autoDeletionServiceProvider);
      await autoDel.purgeItem(widget.item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permanently deleted from device and cloud.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteScreenshot() async {
    if (_selectedCategory == 'Delete') {
      await _permanentDeleteNow();
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceElevated,
        title: const Text('Delete Screenshot'),
        content: const Text(
          'Choose how you want to remove this screenshot:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'move_delete'),
            child: const Text('Move to Delete (30 Days)'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, 'permanent'),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (action == 'move_delete' && mounted) {
      final autoDel = ref.read(autoDeletionServiceProvider);
      await autoDel.moveToDelete(widget.item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Moved to Delete. Auto-deletes in 30 days.'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.pop(context);
      }
    } else if (action == 'permanent' && mounted) {
      final autoDel = ref.read(autoDeletionServiceProvider);
      await autoDel.purgeItem(widget.item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permanently deleted from device and cloud.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _addTag(String raw) {
    final clean = raw.trim().toLowerCase().replaceAll(RegExp(r'[^\w-]'), '');
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(allCategoriesProvider);
    final dropdownCategories = {...allCategories, _selectedCategory}.toList();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Screenshot Details', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete',
            onPressed: _deleteScreenshot,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: AppColors.primary),
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveChanges,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Image Preview Container
          ClipRRect(
            borderRadius: AppSpacing.roundedMd,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 380),
              color: AppColors.darkSurfaceElevated,
              child: Center(child: _buildImagePreview()),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text('TITLE',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _titleController,
            style: AppTypography.titleMedium,
            decoration: const InputDecoration(
              hintText: 'Enter title...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Category Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PRIMARY CATEGORY',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondaryDark)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                label: const Text('New Category',
                    style: TextStyle(fontSize: 12, color: AppColors.primary)),
                onPressed: () async {
                  final newCat = await showAddCategoryDialog(context, ref);
                  if (newCat != null && mounted) {
                    setState(() => _selectedCategory = newCat);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(
                color: _selectedCategory == 'Delete'
                    ? AppColors.error
                    : AppColors.darkBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dropdownCategories.contains(_selectedCategory)
                    ? _selectedCategory
                    : 'Other',
                isExpanded: true,
                dropdownColor: AppColors.darkSurfaceElevated,
                items: dropdownCategories.map((cat) {
                  final isDel = cat == 'Delete';
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        if (isDel) ...[
                          const Icon(Icons.delete_outline,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          cat,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDel
                                ? AppColors.error
                                : AppColors.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
          if (_selectedCategory == 'Delete') ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppSpacing.roundedSm,
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_delete_outlined,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.item.daysUntilDeletion != null
                            ? 'Scheduled deletion in ${widget.item.daysUntilDeletion} days'
                            : 'Auto-deletes after 30 days',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Screenshots in Delete category are permanently purged from your device gallery and cloud storage 30 days after being added.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondaryDark),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.textSecondaryDark),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.restore_from_trash, size: 16),
                        label: const Text('Restore'),
                        onPressed: _isSaving ? null : _restoreFromDelete,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.delete_forever, size: 16),
                        label: const Text('Delete Now'),
                        onPressed: _isSaving ? null : _permanentDeleteNow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Tags Editor
          Text('MICRO-TAGS',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ..._tags.map((tag) => Chip(
                    label: Text('#$tag', style: AppTypography.labelSmall),
                    backgroundColor: AppColors.darkSurfaceElevated,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => _removeTag(tag),
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInputController,
                  decoration: const InputDecoration(
                    hintText: 'Add a tag...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _addTag(_tagInputController.text),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // OCR Extracted Text Card
          if (widget.item.extractedText.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EXTRACTED TEXT (OCR)',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondaryDark)),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.item.extractedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Copied text to clipboard!')),
                    );
                  },
                ),
              ],
            ),
            Container(
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceElevated,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: SelectableText(
                widget.item.extractedText,
                style: AppTypography.bodySmall.copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // User Note Field
          Text('NOTES & PERSONAL CONTEXT',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add personal notes or context...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save Button
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save & Confirm'),
            onPressed: _isSaving ? null : _saveChanges,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (widget.item.localThumbnailPath != null &&
        widget.item.localThumbnailPath!.isNotEmpty) {
      final file = File(widget.item.localThumbnailPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.contain);
      }
    }

    return const Icon(Icons.image, size: 64, color: AppColors.textTertiaryDark);
  }
}
