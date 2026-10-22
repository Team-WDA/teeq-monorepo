import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/debug_console_filters.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

NetworkLogEntry _network(String path, {int? statusCode, Duration? duration}) =>
    NetworkLogEntry(
      id: path,
      startedAt: DateTime.utc(2026, 10, 22),
      method: 'GET',
      url: 'https://api.example.test$path',
      requestHeaders: const {},
      statusCode: statusCode,
      duration: duration,
    );

AppLogEntry _log(AppLogLevel level) => AppLogEntry(
  timestamp: DateTime.utc(2026, 10, 22),
  level: level,
  name: 'Test',
  message: level.name,
);

void main() {
  final pending = _network('/api/pending');
  final success = _network(
    '/api/Members/me',
    statusCode: 200,
    duration: Duration.zero,
  );
  final failure = _network(
    '/api/auth/login',
    statusCode: 401,
    duration: Duration.zero,
  );
  final entries = [pending, success, failure];

  group('filterNetworkEntries', () {
    test('returns everything for an empty query and the all filter', () {
      final result = filterNetworkEntries(
        entries,
        urlQuery: '',
        statusFilter: NetworkLogStatusFilter.all,
      );

      expect(result, entries);
    });

    test('matches the url case-insensitively by substring', () {
      final result = filterNetworkEntries(
        entries,
        urlQuery: 'MEMBERS',
        statusFilter: NetworkLogStatusFilter.all,
      );

      expect(result, [success]);
    });

    test('keeps only successful calls for the success filter', () {
      final result = filterNetworkEntries(
        entries,
        urlQuery: '',
        statusFilter: NetworkLogStatusFilter.success,
      );

      expect(result, [success]);
    });

    test('keeps only failed calls for the failure filter', () {
      final result = filterNetworkEntries(
        entries,
        urlQuery: '',
        statusFilter: NetworkLogStatusFilter.failure,
      );

      expect(result, [failure]);
    });

    test('shows pending calls only under the all filter', () {
      for (final filter in [
        NetworkLogStatusFilter.success,
        NetworkLogStatusFilter.failure,
      ]) {
        final result = filterNetworkEntries(
          entries,
          urlQuery: 'pending',
          statusFilter: filter,
        );

        expect(result, isEmpty);
      }
      expect(
        filterNetworkEntries(
          entries,
          urlQuery: 'pending',
          statusFilter: NetworkLogStatusFilter.all,
        ),
        [pending],
      );
    });

    test('combines the query and the status filter', () {
      final result = filterNetworkEntries(
        entries,
        urlQuery: 'auth',
        statusFilter: NetworkLogStatusFilter.success,
      );

      expect(result, isEmpty);
    });
  });

  group('filterLogsByLevel', () {
    final logs = AppLogLevel.values.map(_log).toList();

    test('keeps everything when all levels are visible', () {
      expect(filterLogsByLevel(logs, AppLogLevel.values.toSet()), logs);
    });

    test('keeps only the visible levels', () {
      final result = filterLogsByLevel(logs, {
        AppLogLevel.warning,
        AppLogLevel.error,
      });

      expect(result.map((log) => log.level), [
        AppLogLevel.warning,
        AppLogLevel.error,
      ]);
    });

    test('returns nothing when no level is visible', () {
      expect(filterLogsByLevel(logs, const {}), isEmpty);
    });
  });
}
