import 'package:teeq/features/call/domain/call_keep_alive.dart';

/// 시작 시 알림 본문과 종료 횟수를 기록하는 테스트용 포그라운드 유지.
class FakeCallKeepAlive implements CallKeepAlive {
  final List<String> startedBodies = <String>[];
  int stopCount = 0;

  @override
  Future<void> start({required String notificationBody}) async {
    startedBodies.add(notificationBody);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }
}
