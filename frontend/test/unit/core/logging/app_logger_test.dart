import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';

import '../../../support/fake_developer_mode_storage.dart';

void main() {
  group('AppLogger', () {
    test('hands level, name, message and error to onEntry', () {
      final entries = <AppLogEntry>[];
      final logger = AppLogger(onEntry: entries.add);

      logger.log(
        '실패',
        name: 'Test',
        level: AppLogLevel.warning,
        error: 'x',
        stackTrace: StackTrace.fromString('#0 main'),
      );

      expect(entries, hasLength(1));
      expect(entries.single.level, AppLogLevel.warning);
      expect(entries.single.name, 'Test');
      expect(entries.single.message, '실패');
      expect(entries.single.errorDescription, 'x');
      expect(entries.single.stackTraceText, '#0 main');
    });

    test('defaults to info level without error details', () {
      final entries = <AppLogEntry>[];

      AppLogger(onEntry: entries.add).log('안내', name: 'Test');

      expect(entries.single.level, AppLogLevel.info);
      expect(entries.single.errorDescription, isNull);
      expect(entries.single.stackTraceText, isNull);
    });

    test('works without an onEntry callback', () {
      expect(() => AppLogger().log('안내', name: 'Test'), returnsNormally);
    });

    test('stamps entries with the injected clock', () {
      final entries = <AppLogEntry>[];
      final moment = DateTime.utc(2026, 10, 22, 9);

      AppLogger(onEntry: entries.add, clock: () => moment).log('x', name: 'T');

      expect(entries.single.timestamp, moment);
    });
  });

  group('appLoggerProvider', () {
    test('writes to the console store only after a microtask', () async {
      final container = ProviderContainer(
        overrides: [
          initialDeveloperModeEnabledProvider.overrideWithValue(true),
          developerModeStorageProvider.overrideWithValue(
            FakeDeveloperModeStorage(storedEnabled: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(appLoggerProvider).log('안내', name: 'Test');

      expect(
        container.read(debugConsoleStoreProvider).applicationLogs,
        isEmpty,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(debugConsoleStoreProvider).applicationLogs,
        hasLength(1),
      );
    });
  });
}
