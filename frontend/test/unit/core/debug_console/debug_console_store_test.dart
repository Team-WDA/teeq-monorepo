import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/bounded_list.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

import '../../../support/fake_developer_mode_storage.dart';

ProviderContainer _container({required bool enabled}) {
  final container = ProviderContainer(
    overrides: [
      initialDeveloperModeEnabledProvider.overrideWithValue(enabled),
      developerModeStorageProvider.overrideWithValue(
        FakeDeveloperModeStorage(storedEnabled: enabled),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AppLogEntry _log(AppLogLevel level, {String message = '메시지'}) => AppLogEntry(
  timestamp: DateTime.utc(2026, 10, 22),
  level: level,
  name: 'Test',
  message: message,
);

NetworkLogEntry _network(String id) => NetworkLogEntry(
  id: id,
  startedAt: DateTime.utc(2026, 10, 22),
  method: 'GET',
  url: 'https://api.example.test/$id',
  requestHeaders: const {},
);

void main() {
  group('while developer mode is off', () {
    test('ignores every recording method', () {
      final container = _container(enabled: false);
      final store = container.read(debugConsoleStoreProvider.notifier);

      store.recordLog(_log(AppLogLevel.error));
      store.recordNetworkStart(_network('1'));
      store.recordNetworkCompletion(
        _network('1').copyWith(statusCode: 200, duration: Duration.zero),
      );

      final state = container.read(debugConsoleStoreProvider);
      expect(state.applicationLogs, isEmpty);
      expect(state.errorLogs, isEmpty);
      expect(state.networkEntries, isEmpty);
      expect(store.isCollecting, isFalse);
    });
  });

  group('while developer mode is on', () {
    test('keeps non-error logs only in the application log list', () {
      final container = _container(enabled: true);

      container
          .read(debugConsoleStoreProvider.notifier)
          .recordLog(_log(AppLogLevel.warning));

      final state = container.read(debugConsoleStoreProvider);
      expect(state.applicationLogs, hasLength(1));
      expect(state.errorLogs, isEmpty);
    });

    test('adds error logs to both lists', () {
      final container = _container(enabled: true);

      container
          .read(debugConsoleStoreProvider.notifier)
          .recordLog(_log(AppLogLevel.error));

      final state = container.read(debugConsoleStoreProvider);
      expect(state.applicationLogs, hasLength(1));
      expect(state.errorLogs, hasLength(1));
    });

    test('replaces a started network entry on completion in place', () {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);
      store.recordNetworkStart(_network('1'));
      store.recordNetworkStart(_network('2'));

      store.recordNetworkCompletion(
        _network(
          '1',
        ).copyWith(statusCode: 200, duration: const Duration(milliseconds: 5)),
      );

      final entries = container.read(debugConsoleStoreProvider).networkEntries;
      expect(entries.map((entry) => entry.id), ['1', '2']);
      expect(entries.first.statusCode, 200);
      expect(entries.last.outcome, NetworkLogOutcome.pending);
    });

    test('ignores the completion of an entry that is not stored', () {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);

      store.recordNetworkCompletion(_network('missing'));

      expect(container.read(debugConsoleStoreProvider).networkEntries, isEmpty);
    });

    test('keeps only the newest 500 entries per list', () {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);

      for (var index = 0; index <= debugConsoleEntryCapacity; index++) {
        store.recordLog(_log(AppLogLevel.info, message: '$index'));
      }

      final logs = container.read(debugConsoleStoreProvider).applicationLogs;
      expect(logs, hasLength(debugConsoleEntryCapacity));
      expect(logs.first.message, '1');
      expect(logs.last.message, '$debugConsoleEntryCapacity');
    });

    test('hands out a different network entry id every time', () {
      final store = _container(enabled: true)
          .read(debugConsoleStoreProvider.notifier);

      expect(store.nextNetworkEntryId(), isNot(store.nextNetworkEntryId()));
    });

    test('clearNetworkEntries leaves the other lists alone', () {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);
      store.recordNetworkStart(_network('1'));
      store.recordLog(_log(AppLogLevel.error));

      store.clearNetworkEntries();

      final state = container.read(debugConsoleStoreProvider);
      expect(state.networkEntries, isEmpty);
      expect(state.applicationLogs, hasLength(1));
      expect(state.errorLogs, hasLength(1));
    });

    test('clearApplicationLogs and clearErrorLogs empty only their list', () {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);
      store.recordLog(_log(AppLogLevel.error));

      store.clearApplicationLogs();
      expect(
        container.read(debugConsoleStoreProvider).applicationLogs,
        isEmpty,
      );
      expect(container.read(debugConsoleStoreProvider).errorLogs, hasLength(1));

      store.clearErrorLogs();
      expect(container.read(debugConsoleStoreProvider).errorLogs, isEmpty);
    });

    test('clearAll empties all three lists', () {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);
      store.recordNetworkStart(_network('1'));
      store.recordLog(_log(AppLogLevel.error));

      store.clearAll();

      final state = container.read(debugConsoleStoreProvider);
      expect(state.networkEntries, isEmpty);
      expect(state.applicationLogs, isEmpty);
      expect(state.errorLogs, isEmpty);
    });

    test('empties every list when developer mode is switched off', () async {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);
      store.recordNetworkStart(_network('1'));
      store.recordLog(_log(AppLogLevel.error));

      await container.read(developerModeControllerProvider.notifier).disable();

      final state = container.read(debugConsoleStoreProvider);
      expect(state.networkEntries, isEmpty);
      expect(state.applicationLogs, isEmpty);
      expect(state.errorLogs, isEmpty);
    });

    test('starts empty again after being switched off and on', () async {
      final container = _container(enabled: true);
      final store = container.read(debugConsoleStoreProvider.notifier);
      store.recordLog(_log(AppLogLevel.info));
      final controller = container.read(
        developerModeControllerProvider.notifier,
      );

      await controller.disable();
      await controller.enable();

      expect(
        container.read(debugConsoleStoreProvider).applicationLogs,
        isEmpty,
      );
    });
  });
}
