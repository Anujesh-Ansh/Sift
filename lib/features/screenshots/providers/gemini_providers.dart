import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../infrastructure/ai/gemini_analyzer_impl.dart';
import '../../../infrastructure/ai/screenshot_analyzer.dart';
import '../../../infrastructure/media/pipeline_coordinator.dart';
import '../../auth/providers/auth_provider.dart';
import 'screenshot_providers.dart';

/// StateNotifier that seamlessly persists Gemini API Key to local device storage.
class GeminiApiKeyNotifier extends StateNotifier<String> {
  GeminiApiKeyNotifier()
      : super(
          const String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
        ) {
    _loadPersistedKey();
  }

  Future<void> _loadPersistedKey() async {
    final key = await AppConfigService.getApiKey();
    if (key.isNotEmpty) {
      state = key;
    }
  }

  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    state = trimmed;
    await AppConfigService.saveApiKey(trimmed);
  }
}

/// Persistent Gemini API key provider across app launches.
final geminiApiKeyProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, String>((ref) {
  return GeminiApiKeyNotifier();
});

/// Multimodal Vision analyzer instance.
final screenshotAnalyzerProvider = Provider<ScreenshotAnalyzer>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  return GeminiAnalyzerImpl(
    apiKey: apiKey,
    modelName: AppConstants.defaultGeminiModel,
  );
});

/// End-to-end Pipeline Coordinator provider.
final pipelineCoordinatorProvider = Provider<PipelineCoordinator>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final analyzer = ref.watch(screenshotAnalyzerProvider);
  final repository = ref.watch(screenshotRepositoryProvider);

  return PipelineCoordinator(
    storageService: storage,
    analyzer: analyzer,
    repository: repository,
    getUserId: () => ref.read(currentUserIdProvider) ?? 'anonymous',
  );
});
