import 'package:photo_manager/photo_manager.dart';
import '../../core/logging/app_logger.dart';

enum MediaPermissionState {
  unknown,
  granted,
  limited,
  denied,
  permanentlyDenied,
  restricted;

  bool get hasAccess =>
      this == MediaPermissionState.granted ||
      this == MediaPermissionState.limited;
}

/// Service managing device media library permissions.
class MediaPermissionService {
  static const _logger = AppLogger('MediaPermissionService');

  /// Checks the current media library permission status.
  Future<MediaPermissionState> checkPermission() async {
    try {
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      return _mapPermissionState(state);
    } catch (e, st) {
      _logger.e('Failed to check media permission', e, st);
      return MediaPermissionState.unknown;
    }
  }

  /// Requests media library access from the user.
  Future<MediaPermissionState> requestPermission() async {
    try {
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      _logger.i('Media permission requested. Result: $state');
      return _mapPermissionState(state);
    } catch (e, st) {
      _logger.e('Failed to request media permission', e, st);
      return MediaPermissionState.denied;
    }
  }

  MediaPermissionState _mapPermissionState(PermissionState state) {
    switch (state) {
      case PermissionState.authorized:
        return MediaPermissionState.granted;
      case PermissionState.limited:
        return MediaPermissionState.limited;
      case PermissionState.denied:
        return MediaPermissionState.denied;
      case PermissionState.restricted:
        return MediaPermissionState.restricted;
      case PermissionState.notDetermined:
        return MediaPermissionState.unknown;
    }
  }
}
