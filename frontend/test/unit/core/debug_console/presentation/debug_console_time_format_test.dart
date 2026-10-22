import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_time_format.dart';

void main() {
  test('formats local time as HH:mm:ss.SSS with zero padding', () {
    final moment = DateTime(2026, 10, 22, 3, 4, 5, 6);

    expect(formatConsoleTime(moment), '03:04:05.006');
  });

  test('converts UTC times to local time before formatting', () {
    final utc = DateTime.utc(2026, 10, 22, 10, 20, 30, 400);

    expect(formatConsoleTime(utc), formatConsoleTime(utc.toLocal()));
  });
}
