import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../logging/app_logger.dart';

/// Persists local user configuration (e.g. Gemini API Key) across app restarts and updates.
class AppConfigService {
  static const _logger = AppLogger('AppConfigService');
  static const _configFileName = 'sift_config.json';

  static String? _cachedApiKey;

  /// Retrieves the persisted Gemini API key or falls back to compile-time env.
  static Future<String> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }

    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content);
        if (map is Map<String, dynamic> && map['gemini_api_key'] is String) {
          final key = (map['gemini_api_key'] as String).trim();
          if (key.isNotEmpty) {
            _cachedApiKey = key;
            return key;
          }
        }
      }
    } catch (e, st) {
      _logger.w('Failed reading persisted config: $e', e, st);
    }

    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    _cachedApiKey = envKey;
    return envKey;
  }

  /// Persists the Gemini API key to local application documents directory.
  static Future<void> saveApiKey(String key) async {
    _cachedApiKey = key.trim();
    try {
      final file = await _getConfigFile();
      Map<String, dynamic> current = {};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          current = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {}
      }
      current['gemini_api_key'] = key.trim();
      current['updated_at'] = DateTime.now().toIso8601String();
      await file.writeAsString(jsonEncode(current), flush: true);
      _logger.i('Successfully persisted Gemini API key to local config file.');
    } catch (e, st) {
      _logger.e('Failed saving Gemini API key to config file: $e', e, st);
    }
  }

  static Future<File> _getConfigFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_configFileName');
  }
}
