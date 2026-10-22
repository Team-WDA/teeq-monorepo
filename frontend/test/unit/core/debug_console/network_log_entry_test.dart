import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';

NetworkLogEntry _entry({
  int? statusCode,
  Duration? duration,
  String? errorDescription,
}) => NetworkLogEntry(
  id: '1',
  startedAt: DateTime.utc(2026, 10, 22),
  method: 'GET',
  url: 'https://api.example.test/a',
  requestHeaders: const {},
  statusCode: statusCode,
  duration: duration,
  errorDescription: errorDescription,
);

void main() {
  group('NetworkLogEntry.outcome', () {
    test('is pending until a duration is recorded', () {
      expect(_entry().outcome, NetworkLogOutcome.pending);
    });

    test('is success for a 2xx response without an error', () {
      final entry = _entry(
        statusCode: 200,
        duration: const Duration(milliseconds: 10),
      );

      expect(entry.outcome, NetworkLogOutcome.success);
    });

    test('is failure for a non-2xx response', () {
      final entry = _entry(
        statusCode: 401,
        duration: const Duration(milliseconds: 10),
      );

      expect(entry.outcome, NetworkLogOutcome.failure);
    });

    test('is failure when there is no status code but an error', () {
      final entry = _entry(
        duration: const Duration(milliseconds: 10),
        errorDescription: 'connectionError',
      );

      expect(entry.outcome, NetworkLogOutcome.failure);
    });
  });

  test('copyWith replaces only the given fields', () {
    final pending = _entry();

    final completed = pending.copyWith(
      statusCode: 204,
      duration: const Duration(milliseconds: 5),
    );

    expect(completed.id, pending.id);
    expect(completed.url, pending.url);
    expect(completed.statusCode, 204);
    expect(completed.duration, const Duration(milliseconds: 5));
  });
}
