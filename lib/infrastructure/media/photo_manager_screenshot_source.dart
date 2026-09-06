import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import '../../core/logging/app_logger.dart';
import 'models/screenshot_candidate.dart';
import 'screenshot_source.dart';

/// Production implementation of ScreenshotSource using photo_manager.
class PhotoManagerScreenshotSource implements ScreenshotSource {
  static const _logger = AppLogger('PhotoManagerScreenshotSource');

  @override
  Future<List<ScreenshotCandidate>> fetchScreenshotCandidates({
    int page = 0,
    int size = 50,
    DateTime? since,
  }) async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          createTimeCond: since != null
              ? DateTimeCond(min: since, max: DateTime.now())
              : DateTimeCond.def(),
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      if (albums.isEmpty) {
        _logger.d('No image albums found on device');
        return [];
      }

      // Prioritize albums explicitly named 'Screenshots'
      AssetPathEntity targetAlbum = albums.firstWhere(
        (a) => a.name.toLowerCase().contains('screenshot'),
        orElse: () => albums.first,
      );

      _logger
          .d('Querying album: ${targetAlbum.name} (page: $page, size: $size)');

      final assets = await targetAlbum.getAssetListPaged(
        page: page,
        size: size,
      );

      final List<ScreenshotCandidate> candidates = [];

      for (final asset in assets) {
        // If from a general album, apply screenshot heuristic
        if (!targetAlbum.name.toLowerCase().contains('screenshot') &&
            !_isScreenshotHeuristic(asset)) {
          continue;
        }

        candidates.add(
          ScreenshotCandidate(
            id: asset.id,
            title: asset.title ??
                'Screenshot-${asset.createDateTime.millisecondsSinceEpoch}',
            createDateTime: asset.createDateTime,
            modifiedDateTime: asset.modifiedDateTime,
            width: asset.width,
            height: asset.height,
          ),
        );
      }

      _logger.i(
          'Discovered ${candidates.length} screenshot candidates on page $page');
      return candidates;
    } catch (e, st) {
      _logger.e('Failed to fetch screenshot candidates', e, st);
      return [];
    }
  }

  @override
  Future<File?> getAssetFile(String assetId) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) return null;
      return await asset.file;
    } catch (e, st) {
      _logger.e('Failed to retrieve file for asset: $assetId', e, st);
      return null;
    }
  }

  @override
  Future<Uint8List?> getThumbnailBytes(
    String assetId, {
    int width = 250,
    int height = 250,
  }) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) return null;
      return await asset.thumbnailDataWithSize(
        ThumbnailSize(width, height),
        quality: 70,
      );
    } catch (e, st) {
      _logger.e('Failed to get thumbnail bytes for asset: $assetId', e, st);
      return null;
    }
  }

  @override
  Future<bool> assetExists(String assetId) async {
    try {
      final asset = await AssetEntity.fromId(assetId);
      return asset != null && await asset.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteAsset(String assetId) async {
    try {
      final result = await PhotoManager.editor.deleteWithIds([assetId]);
      final success = result.contains(assetId);
      if (success) {
        _logger.i('Successfully deleted asset from gallery: $assetId');
      } else {
        _logger.w('Failed to delete asset (not in result list): $assetId');
      }
      return success;
    } catch (e, st) {
      _logger.e('Error deleting asset from gallery: $assetId', e, st);
      return false;
    }
  }

  bool _isScreenshotHeuristic(AssetEntity asset) {
    final title = (asset.title ?? '').toLowerCase();
    return title.startsWith('screenshot') ||
        title.contains('screen_shot') ||
        title.contains('screenshot_') ||
        title.contains('screencapture');
  }
}
