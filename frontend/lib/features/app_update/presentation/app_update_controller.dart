import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/features/app_update/data/app_update_repository_impl.dart';
import 'package:teeq/features/app_update/domain/app_platform.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';

part 'app_update_controller.g.dart';

/// 실행 중인 플랫폼. 최소버전을 검사하지 않는 플랫폼이면 null이다.
@Riverpod(keepAlive: true)
AppPlatform? currentAppPlatform(Ref ref) => switch (defaultTargetPlatform) {
  TargetPlatform.android => AppPlatform.android,
  TargetPlatform.iOS => AppPlatform.ios,
  _ => null,
};

/// 앱 업데이트 필요 여부를 보관한다. 상태가 null이면 업데이트가 필요 없거나 아직 확인하지 않은 것이다.
@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  @override
  AppUpdateRequirement? build() => null;

  /// 최소버전을 검사해 업데이트가 필요하면 상태를 채우고 true를 돌려준다.
  /// 호출 실패·타임아웃·응답 이상은 어떤 예외도 던지지 않고 통과(false)시킨다(fail-open).
  /// 응답 변환 오류(`TypeError` 등)로 스플래시가 멈추지 않게 `Object`까지 잡는다.
  Future<bool> check() async {
    final platform = ref.read(currentAppPlatformProvider);
    if (platform == null) {
      return false;
    }
    try {
      final appVersion = await ref.read(appVersionProvider.future);
      final requirement = await ref
          .read(appUpdateRepositoryProvider)
          .checkRequirement(platform: platform, appVersion: appVersion);
      if (requirement == null) {
        return false;
      }
      state = requirement;
      return true;
    } on Object catch (error, stackTrace) {
      ref
          .read(appLoggerProvider)
          .log(
            '앱 최소버전 검사 실패, 통과 처리: $error',
            name: 'AppUpdateController',
            level: AppLogLevel.warning,
            error: error,
            stackTrace: stackTrace,
          );
      return false;
    }
  }
}
