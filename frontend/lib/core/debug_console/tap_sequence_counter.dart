/// 연속 탭 횟수를 세는 이스터에그 감지기.
///
/// 직전 탭과의 간격이 [resetAfter]를 넘으면 다시 처음부터 센다.
final class TapSequenceCounter {
  TapSequenceCounter({
    this.requiredTaps = 7,
    this.resetAfter = const Duration(seconds: 2),
  });

  final int requiredTaps;
  final Duration resetAfter;

  int _tapCount = 0;
  DateTime? _lastTapAt;

  /// 탭 한 번을 등록한다. 필요한 횟수에 도달한 탭이면 true를 돌려주고 횟수를 0으로 되돌린다.
  bool register(DateTime now) {
    final lastTapAt = _lastTapAt;
    final isWithinWindow =
        lastTapAt != null && now.difference(lastTapAt) <= resetAfter;
    _tapCount = isWithinWindow ? _tapCount + 1 : 1;
    _lastTapAt = now;
    if (_tapCount < requiredTaps) {
      return false;
    }
    _tapCount = 0;
    _lastTapAt = null;
    return true;
  }
}
