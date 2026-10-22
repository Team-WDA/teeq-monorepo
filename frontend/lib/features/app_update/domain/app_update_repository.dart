import 'package:teeq/features/app_update/domain/app_platform.dart';
import 'package:teeq/features/app_update/domain/app_update_requirement.dart';

/// 앱 최소버전 검사 API.
abstract interface class AppUpdateRepository {
  /// 설치된 [appVersion]이 [platform]의 최소버전에 못 미치면 요구사항을, 아니면 null을 돌려준다.
  Future<AppUpdateRequirement?> checkRequirement({
    required AppPlatform platform,
    required String appVersion,
  });
}
