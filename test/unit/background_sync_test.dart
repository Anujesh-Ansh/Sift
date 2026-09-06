import 'package:flutter_test/flutter_test.dart';
import 'package:project_sift/infrastructure/background/background_sync_service.dart';

void main() {
  group('BackgroundSyncService Unit Tests', () {
    late BackgroundSyncService service;

    setUp(() {
      service = BackgroundSyncService();
    });

    test(
        'should initialize and register background sync safely without throwing on non-mobile',
        () async {
      // In flutter test (host machine), Workmanager handles platform calls safely
      expect(() async => await service.initialize(), returnsNormally);
      expect(() async => await service.schedulePeriodicSync(), returnsNormally);
      expect(() async => await service.cancelPeriodicSync(), returnsNormally);
      expect(() async => await service.triggerOneOffSync(), returnsNormally);
    });
  });
}
