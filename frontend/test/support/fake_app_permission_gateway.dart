import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_gateway.dart';
import 'package:teeq/core/permission/app_permission_status.dart';
import 'package:teeq/core/permission/microphone_permission_prompt.dart';

/// 권한 상태를 메모리에 두고 호출 횟수를 기록하는 테스트용 권한 게이트웨이.
class FakeAppPermissionGateway implements AppPermissionGateway {
  FakeAppPermissionGateway({
    this.initialStatus = AppPermissionStatus.denied,
    this.requestResult = AppPermissionStatus.granted,
  }) : _currentStatus = initialStatus;

  final AppPermissionStatus initialStatus;

  /// [request]가 돌려줄 결과. 요청 뒤에는 이 값이 현재 상태가 된다.
  final AppPermissionStatus requestResult;

  AppPermissionStatus _currentStatus;

  int requestCount = 0;
  int openSettingsCount = 0;

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async =>
      _currentStatus;

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async {
    requestCount += 1;
    _currentStatus = requestResult;
    return requestResult;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCount += 1;
  }
}

/// 메모리에 "마이크 권한을 이미 물었는지" 플래그를 보관하는 테스트용 저장소.
class FakeMicrophonePromptStorage implements MicrophonePromptStorage {
  FakeMicrophonePromptStorage({this.prompted = false});

  bool prompted;

  @override
  Future<bool> hasPrompted() async => prompted;

  @override
  Future<void> markPrompted() async {
    prompted = true;
  }
}

/// 홈 화면 테스트용 마이크 권한 안내. 실제 요청 없이 호출 횟수만 기록한다.
class FakeMicrophonePermissionPrompt implements MicrophonePermissionPrompt {
  int requestOnceCount = 0;

  @override
  Future<void> requestOnceIfNeeded() async {
    requestOnceCount += 1;
  }
}
