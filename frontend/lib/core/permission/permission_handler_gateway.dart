import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_gateway.dart';
import 'package:teeq/core/permission/app_permission_status.dart';

part 'permission_handler_gateway.g.dart';

/// `permission_handler`로 기기 권한을 조회·요청하는 실제 구현.
///
/// 플랫폼별 거절 상태가 다르다(permission_handler 13.x).
/// - 안드로이드: `status`는 영구 거절(permanentlyDenied)을 돌려주지 않고 거절이면 항상 denied다.
///   영구 거절은 `request()` 결과로만 알 수 있다.
/// - iOS: 사용자가 한 번만 거절해도 곧바로 permanentlyDenied가 온다.
final class PermissionHandlerGateway implements AppPermissionGateway {
  const PermissionHandlerGateway();

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async =>
      _toAppStatus(await _toPlatformPermission(permission).status);

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async =>
      _toAppStatus(await _toPlatformPermission(permission).request());

  @override
  Future<void> openSettings() => openAppSettings();

  Permission _toPlatformPermission(AppPermission permission) =>
      switch (permission) {
        AppPermission.microphone => Permission.microphone,
      };

  AppPermissionStatus _toAppStatus(PermissionStatus status) {
    if (status.isGranted) {
      return AppPermissionStatus.granted;
    }
    // iOS 스크린 타임 등으로 제한된 상태(restricted)는 앱이 다시 요청해도 바뀌지 않으므로
    // 영구 거절로 취급해 설정으로 안내한다.
    if (status.isPermanentlyDenied || status.isRestricted) {
      return AppPermissionStatus.permanentlyDenied;
    }
    return AppPermissionStatus.denied;
  }
}

@Riverpod(keepAlive: true)
AppPermissionGateway appPermissionGateway(Ref ref) =>
    const PermissionHandlerGateway();
