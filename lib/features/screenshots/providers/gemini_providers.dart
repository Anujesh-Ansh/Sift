import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../infrastructure/ai/gemini_analyzer_impl.dart';
import '../../../infrastructure/ai/screenshot_analyzer.dart';
import '../../../infrastructure/media/pipeline_coordinator.dart';
import '../../auth/providers/auth_provider.dart';
import 'screenshot_providers.dart';

/// Configurable Gemini API key state (defaults to compile-time env variable).
final geminiApiKeyProvider = StateProvider<String>((ref) {
  return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
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
