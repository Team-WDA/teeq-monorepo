import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_minimum_display_controller.g.dart';

/// 스플래시를 최소한 보여 주는 시간. 로고를 볼 수 있을 만큼 머물게 한다.
const splashMinimumDisplayDuration = Duration(milliseconds: 1500);

/// 앱 시작 후 스플래시 최소 노출 시간이 지났는지 보관한다. 지나기 전에는 false, 지나면 true.
/// 토큰 복원이 더 오래 걸려도 이 값은 영향을 주지 않으며, 복원이 끝나는 즉시 넘어간다.
@Riverpod(keepAlive: true)
class SplashMinimumDisplayController extends _$SplashMinimumDisplayController {
  @override
  bool build() {
    final timer = Timer(splashMinimumDisplayDuration, () {
      state = true;
    });
    ref.onDispose(timer.cancel);
    return false;
  }
}
