import 'package:teeq/features/call/domain/call_proximity_screen.dart';

/// 호출을 기록하는 테스트용 근접 센서 화면 끄기. `enable`은 true, `disable`은 false로 쌓는다.
class FakeCallProximityScreen implements CallProximityScreen {
  final List<bool> enabledCalls = <bool>[];

  @override
  Future<void> enable() async {
    enabledCalls.add(true);
  }

  @override
  Future<void> disable() async {
    enabledCalls.add(false);
  }
}
