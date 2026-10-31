import 'dart:async';

import 'package:teeq/features/call/domain/call_timing.dart';

/// 통화 세션의 타이머(워커 입장 대기, 재연결 카드 유예, 경과 시간 갱신)를 한곳에서 관리한다.
final class CallSessionTimers {
  CallSessionTimers(this._timing);

  static const Duration _elapsedRefreshInterval = Duration(seconds: 1);

  final CallTiming _timing;
  Timer? _agentWaitTimer;
  Timer? _reconnectNoticeTimer;
  Timer? _elapsedRefreshTimer;

  /// 워커 입장 대기 시간이 지나면 [onTimeout]을 부른다. 이미 재고 있으면 다시 잰다.
  void startAgentWait(void Function() onTimeout) {
    _agentWaitTimer?.cancel();
    _agentWaitTimer = Timer(_timing.agentWaitTimeout, onTimeout);
  }

  void cancelAgentWait() => _agentWaitTimer?.cancel();

  /// 재연결 유예 시간이 지나면 [onGraceElapsed]를 부른다. 이미 재고 있으면 처음 시각을 유지한다.
  void startReconnectNoticeGrace(void Function() onGraceElapsed) {
    if (_reconnectNoticeTimer?.isActive ?? false) {
      return;
    }
    _reconnectNoticeTimer = Timer(_timing.reconnectNoticeGrace, onGraceElapsed);
  }

  void cancelReconnectNoticeGrace() => _reconnectNoticeTimer?.cancel();

  /// 1초마다 [onTick]을 부른다. 화면 갱신용이며 경과 값은 부르는 쪽이 시각 차이로 계산한다.
  void startElapsedRefresh(void Function() onTick) {
    _elapsedRefreshTimer?.cancel();
    _elapsedRefreshTimer = Timer.periodic(
      _elapsedRefreshInterval,
      (_) => onTick(),
    );
  }

  void cancelAll() {
    _agentWaitTimer?.cancel();
    _reconnectNoticeTimer?.cancel();
    _elapsedRefreshTimer?.cancel();
  }
}
