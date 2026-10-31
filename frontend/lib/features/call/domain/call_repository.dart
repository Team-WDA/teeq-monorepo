import 'package:teeq/features/call/domain/call_limit_status.dart';
import 'package:teeq/features/call/domain/call_start_info.dart';

/// 통화 API.
abstract interface class CallRepository {
  /// 통화를 시작하고 LiveKit 접속 정보를 받는다.
  Future<CallStartInfo> startCall();

  /// 오늘 남은 통화 가능 시간을 조회한다.
  Future<CallLimitStatus> fetchTodayLimitStatus();
}
