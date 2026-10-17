import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';

/// 테스트에서 초기 로그인 상태를 정하는 가짜 컨트롤러.
class FakeAuthStatusController extends AuthStatusController {
  FakeAuthStatusController(this._initialStatus);

  final AuthStatus _initialStatus;

  @override
  AuthStatus build() => _initialStatus;
}
