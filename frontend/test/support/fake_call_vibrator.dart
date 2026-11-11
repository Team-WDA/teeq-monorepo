import 'package:teeq/features/call/domain/call_vibrator.dart';

/// 호출을 문자열로 기록하는 테스트용 진동기. 기록 형식: `start`, `stop`.
class FakeCallVibrator implements CallVibrator {
  final List<String> calls = [];

  @override
  Future<void> startRinging() async {
    calls.add('start');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }
}
