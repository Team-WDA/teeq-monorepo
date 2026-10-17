import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status.dart';

part 'auth_status_controller.g.dart';

/// 앱 전역 로그인 상태 보관소. 라우터 리다이렉트와 [ErrorHandler]가 읽고 바꾼다.
/// 실제 로그인·토큰 복원 로직은 인증 이슈에서 채운다.
@Riverpod(keepAlive: true)
class AuthStatusController extends _$AuthStatusController {
  @override
  AuthStatus build() {
    // 저장된 토큰을 아직 다루지 않으므로 사실에 맞게 signedOut에서 시작한다.
    // AuthStatus.unknown은 인증 이슈에서 비동기 복원을 도입할 때 초기값으로 쓰기 위해 남겨 둔다.
    return AuthStatus.signedOut;
  }

  void markSignedIn() {
    state = AuthStatus.signedIn;
  }

  void markSignedOut() {
    state = AuthStatus.signedOut;
  }
}
