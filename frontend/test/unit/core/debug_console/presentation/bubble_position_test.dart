import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/presentation/bubble_position.dart';

const _screen = Size(400, 800);
const _safePadding = EdgeInsets.fromLTRB(0, 44, 0, 34);
const _diameter = 52.0;

Offset _clamp(Offset offset, {Size screen = _screen, EdgeInsets? padding}) =>
    clampBubbleOffset(
      offset: offset,
      screenSize: screen,
      safePadding: padding ?? _safePadding,
      bubbleDiameter: _diameter,
    );

void main() {
  test('leaves an offset that is already inside untouched', () {
    expect(_clamp(const Offset(100, 200)), const Offset(100, 200));
  });

  test('pulls a negative offset to the safe area edge', () {
    expect(_clamp(const Offset(-10, -10)), const Offset(0, 44));
  });

  test('keeps the whole bubble inside on the right and bottom edges', () {
    expect(_clamp(const Offset(1000, 1000)), const Offset(348, 714));
  });

  test('respects the left and right safe padding', () {
    const padding = EdgeInsets.fromLTRB(20, 0, 30, 0);

    expect(_clamp(const Offset(0, 0), padding: padding), const Offset(20, 0));
    expect(
      _clamp(const Offset(1000, 0), padding: padding),
      const Offset(318, 0),
    );
  });

  test('returns the top left safe corner when the bubble does not fit', () {
    expect(
      _clamp(const Offset(30, 30), screen: const Size(40, 40)),
      const Offset(0, 44),
    );
  });
}
