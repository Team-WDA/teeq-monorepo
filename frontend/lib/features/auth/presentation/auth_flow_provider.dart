import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/data/firebase_auth_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';

part 'auth_flow_provider.g.dart';

@Riverpod(keepAlive: true)
AuthFlow authFlow(Ref ref) {
  final credentialProvider = ref.watch(authCredentialProviderProvider);
  // 세션이 만료돼 로그아웃 상태로 바뀌면 남은 Firebase·Google 세션도 정리한다.
  // core가 features/auth/data를 참조하지 않도록 이 연결은 여기서 한다. 실패는 무시한다.
  ref.listen(authStatusControllerProvider, (previous, next) {
    if (previous == AuthStatus.signedIn && next == AuthStatus.signedOut) {
      _signOutOfCredentialSessionIgnoringFailure(credentialProvider.signOut);
    }
  });
  return AuthFlow(
    repository: ref.watch(authRepositoryProvider),
    credentialProvider: credentialProvider,
    session: ref.watch(authSessionProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    readStatus: () => ref.read(authStatusControllerProvider),
    reportError: ref.read(errorHandlerProvider).handle,
    isSignupRequired: isSignupRequiredError,
    isStateConflict: isStateConflictError,
    isEmailAlreadyInUse: isEmailAlreadyInUseError,
    isInvalidCredentials: isInvalidCredentialsError,
    isDefinitiveSignupRejection: isDefinitiveSignupRejectionError,
  );
}

Future<void> _signOutOfCredentialSessionIgnoringFailure(
  Future<void> Function() signOut,
) async {
  try {
    await signOut();
  } on Object {
    // 세션 정리 실패는 로그아웃을 막지 않는다.
  }
}

/// 로그인 오류가 가입이 필요한 계정(`AUTH_SIGNUP_REQUIRED`)인지 판정한다.
/// 저장소는 `DioException`으로 감싸 던지므로 [AppException.from]으로 풀어서 본다.
bool isSignupRequiredError(Object error) =>
    _hasErrorCode(error, ErrorCode.authSignupRequired);

/// 가입 오류가 서버에서 이미 가입이 끝난 계정이라는 오류(`STATE_CONFLICT`)인지 판정한다.
bool isStateConflictError(Object error) =>
    _hasErrorCode(error, ErrorCode.stateConflict);

/// Firebase 계정 생성 오류가 이미 가입된 이메일인지 판정한다.
bool isEmailAlreadyInUseError(Object error) =>
    AppException.from(error) is EmailAlreadyInUseException;

/// 이메일 로그인 오류가 이메일 또는 비밀번호 불일치인지 판정한다.
bool isInvalidCredentialsError(Object error) =>
    AppException.from(error) is InvalidCredentialsException;

/// 가입 오류가 서버의 확정 거절(HTTP 400, 401)인지 판정한다. 네트워크 오류와 5xx, 409는 아니다.
bool isDefinitiveSignupRejectionError(Object error) {
  final exception = AppException.from(error);
  return exception is ApiException &&
      (exception.httpStatus == 400 || exception.httpStatus == 401);
}

bool _hasErrorCode(Object error, ErrorCode errorCode) {
  final exception = AppException.from(error);
  return exception is ApiException && exception.errorCode == errorCode;
}
