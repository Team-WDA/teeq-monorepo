import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';

part 'developer_mode_controller.g.dart';

/// 앱 시작 때 저장소에서 읽은 활성화 여부. `main`에서 override한다.
@Riverpod(keepAlive: true)
bool initialDeveloperModeEnabled(Ref ref) => false;

/// 개발자 모드가 켜져 있는지 보관한다. 켜고 끈 값은 저장소에 남겨 앱을 다시 켜도 유지한다.
///
/// 끌 때 콘솔 버퍼를 비우는 일은 `DebugConsoleStore`가 이 상태를 지켜보며 한다.
@Riverpod(keepAlive: true)
class DeveloperModeController extends _$DeveloperModeController {
  @override
  bool build() => ref.read(initialDeveloperModeEnabledProvider);

  Future<void> enable() => _switchTo(true);

  Future<void> disable() => _switchTo(false);

  /// 상태를 먼저 바꾸고 저장한다. 저장에 실패해도 이번 실행에서는 바뀐 상태를 유지한다.
  Future<void> _switchTo(bool enabled) async {
    state = enabled;
    try {
      await ref.read(developerModeStorageProvider).writeEnabled(enabled);
    } on Object catch (error) {
      log(
        '개발자 모드 설정 저장 실패: $error',
        name: 'DeveloperModeController',
        level: 900,
      );
    }
  }
}
