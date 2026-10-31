import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_status.dart';

/// 기기 권한 조회·요청 계약. 테스트에서는 메모리 구현으로 바꾼다.
abstract interface class AppPermissionGateway {
  Future<AppPermissionStatus> status(AppPermission permission);

  Future<AppPermissionStatus> request(AppPermission permission);

  /// 시스템 설정 화면을 연다.
  Future<void> openSettings();
}
