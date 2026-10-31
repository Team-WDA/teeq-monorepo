import 'dart:async';

import 'package:teeq/features/call/domain/call_limit_status.dart';
import 'package:teeq/features/call/domain/call_repository.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';

/// 호출 횟수를 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 통화 저장소.
class FakeCallRepository implements CallRepository {
  FakeCallRepository({
    this.startInfo,
    this.startError,
    this.limitStatus,
    this.limitError,
    this.startGate,
  });

  final CallStartInfo? startInfo;

  /// 지정하면 [startCall]이 이 오류를 던진다.
  final Object? startError;

  final CallLimitStatus? limitStatus;

  /// 지정하면 [fetchTodayLimitStatus]가 이 오류를 던진다.
  final Object? limitError;

  /// 지정하면 [startCall]이 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용).
  final Completer<void>? startGate;

  int startCallCount = 0;

  @override
  Future<CallStartInfo> startCall() async {
    startCallCount += 1;
    await startGate?.future;
    final failure = startError;
    if (failure != null) {
      throw failure;
    }
    return startInfo!;
  }

  @override
  Future<CallLimitStatus> fetchTodayLimitStatus() async {
    final failure = limitError;
    if (failure != null) {
      throw failure;
    }
    return limitStatus!;
  }
}
