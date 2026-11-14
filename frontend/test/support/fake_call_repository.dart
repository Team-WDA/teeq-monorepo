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
    this.cancelError,
    this.cancelGate,
  });

  final CallStartInfo? startInfo;

  /// 지정하면 [startCall]이 이 오류를 던진다.
  final Object? startError;

  final CallLimitStatus? limitStatus;

  /// 지정하면 [fetchTodayLimitStatus]가 이 오류를 던진다.
  final Object? limitError;

  /// 지정하면 [startCall]이 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용).
  Completer<void>? startGate;

  /// 지정하면 [cancelCall]이 이 오류를 던진다(테스트 중 바꿀 수 있다).
  Object? cancelError;

  /// 지정하면 [cancelCall]이 이 게이트가 완료될 때까지 기다린다(취소 응답 지연 재현용).
  Completer<void>? cancelGate;

  int startCallCount = 0;

  /// [cancelCall]이 받은 통화 세션 ID 기록.
  final List<String> cancelledCallSessionIds = <String>[];

  /// 시작·취소 호출 순서. 순서 검증용이다.
  final List<String> operations = <String>[];

  @override
  Future<CallStartInfo> startCall() async {
    startCallCount += 1;
    operations.add('startCall');
    await startGate?.future;
    final failure = startError;
    if (failure != null) {
      throw failure;
    }
    return startInfo!;
  }

  @override
  Future<void> cancelCall(String callSessionId) async {
    cancelledCallSessionIds.add(callSessionId);
    operations.add('cancelCall');
    await cancelGate?.future;
    final failure = cancelError;
    if (failure != null) {
      throw failure;
    }
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
