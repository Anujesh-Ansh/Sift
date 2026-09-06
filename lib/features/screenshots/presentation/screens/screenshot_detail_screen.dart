import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../infrastructure/ai/category_classifier.dart';
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

      await repo.updateReviewStatus(
        widget.item.id,
        status: isCategoryCorrected
            ? ReviewStatus.corrected
            : ReviewStatus.approved,
        correctedCategory: _selectedCategory,
        tags: _tags,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

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

  Future<void> _deleteScreenshot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Screenshot'),
        content: const Text(
          'Are you sure you want to delete this screenshot from Project Sift? This will remove all cloud indexing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(screenshotRepositoryProvider);
      await repo.deleteScreenshot(widget.item.id);
      if (mounted) {
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
          Text('PRIMARY CATEGORY',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondaryDark)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: AppColors.darkSurfaceElevated,
                items: CategoryClassifier.canonicalCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: AppTypography.bodyMedium),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),
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
