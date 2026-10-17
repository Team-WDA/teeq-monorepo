import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status.dart';

part 'auth_status_controller.g.dart';

/// 앱 전역 로그인 상태 보관소. 라우터 리다이렉트와 [ErrorHandler]가 읽고 바꾼다.
/// 저장된 토큰 복원이 끝날 때까지 [AuthStatus.unknown]으로 시작한다.
@Riverpod(keepAlive: true)
class AuthStatusController extends _$AuthStatusController {
  @override
  AuthStatus build() {
    return AuthStatus.unknown;
  }

  void markSignedIn() {
    state = AuthStatus.signedIn;
  }

  void markSignedOut() {
    state = AuthStatus.signedOut;
  }
}
