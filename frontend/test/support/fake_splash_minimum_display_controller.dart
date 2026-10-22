import 'package:teeq/core/router/splash_minimum_display_controller.dart';

/// 테스트에서 스플래시 최소 노출 시간의 경과 여부를 처음부터 정하는 가짜 컨트롤러. 타이머를 만들지 않는다.
class FakeSplashMinimumDisplayController
    extends SplashMinimumDisplayController {
  FakeSplashMinimumDisplayController(this._initialElapsed);

  final bool _initialElapsed;

  @override
  bool build() => _initialElapsed;
}
