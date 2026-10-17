import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_controller.g.dart';

/// 토스트가 화면에 머무는 시간. 테스트에서 override해 짧게 바꾼다.
@Riverpod(keepAlive: true)
Duration toastDisplayDuration(Ref ref) => const Duration(seconds: 3);

/// 현재 표시 중인 토스트 문구를 보관한다. 없으면 null.
@Riverpod(keepAlive: true)
class ToastController extends _$ToastController {
  Timer? _dismissTimer;

  @override
  String? build() {
    ref.onDispose(() => _dismissTimer?.cancel());
    return null;
  }

  /// 같은 문구가 이미 표시 중이면 무시하고, 다른 문구면 교체하며 타이머를 다시 시작한다.
  void show(String message) {
    if (state == message) {
      return;
    }
    _dismissTimer?.cancel();
    state = message;
    _dismissTimer = Timer(ref.read(toastDisplayDurationProvider), () {
      state = null;
    });
  }
}
