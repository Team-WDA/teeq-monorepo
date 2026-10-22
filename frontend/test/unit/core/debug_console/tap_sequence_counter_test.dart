import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/tap_sequence_counter.dart';

final _start = DateTime.utc(2026, 10, 22, 10);

/// [count]번 탭을 [interval] 간격으로 등록하고 마지막 결과를 돌려준다.
List<bool> _tap(
  TapSequenceCounter counter, {
  required int count,
  Duration interval = const Duration(seconds: 1),
  DateTime? from,
}) {
  var moment = from ?? _start;
  final results = <bool>[];
  for (var index = 0; index < count; index++) {
    results.add(counter.register(moment));
    moment = moment.add(interval);
  }
  return results;
}

void main() {
  test('activates only on the seventh consecutive tap', () {
    final results = _tap(TapSequenceCounter(), count: 7);

    expect(results.take(6), everyElement(isFalse));
    expect(results.last, isTrue);
  });

  test('needs seven more taps after activating', () {
    final counter = TapSequenceCounter();
    _tap(counter, count: 7);

    final results = _tap(
      counter,
      count: 7,
      from: _start.add(const Duration(seconds: 10)),
    );

    expect(results.take(6), everyElement(isFalse));
    expect(results.last, isTrue);
  });

  test('restarts the count when the gap exceeds the reset time', () {
    final counter = TapSequenceCounter();
    _tap(counter, count: 3);

    final results = _tap(
      counter,
      count: 7,
      from: _start.add(const Duration(seconds: 10)),
    );

    expect(results.take(6), everyElement(isFalse));
    expect(results.last, isTrue);
  });

  test('keeps counting when the gap equals the reset time', () {
    final counter = TapSequenceCounter();

    final results = _tap(
      counter,
      count: 7,
      interval: const Duration(seconds: 2),
    );

    expect(results.last, isTrue);
  });

  test('does not activate with six taps', () {
    final results = _tap(TapSequenceCounter(), count: 6);

    expect(results, everyElement(isFalse));
  });
}
