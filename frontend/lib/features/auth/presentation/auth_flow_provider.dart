import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/data/sign_in_with_apple_credential_provider.dart';
import 'package:teeq/features/auth/domain/auth_flow.dart';

part 'auth_flow_provider.g.dart';

@Riverpod(keepAlive: true)
AuthFlow authFlow(Ref ref) {
  return AuthFlow(
    repository: ref.watch(authRepositoryProvider),
    appleCredentialProvider: ref.watch(appleCredentialProviderProvider),
    session: ref.watch(authSessionProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    readStatus: () => ref.read(authStatusControllerProvider),
    reportError: ref.read(errorHandlerProvider).handle,
    isSignupAlreadyCompleted: isSignupAlreadyCompletedError,
  );
}

/// 가입 완료 요청이 서버에서 이미 가입이 끝난 회원이라는 오류(`STATE_CONFLICT`)인지 판정한다.
/// 저장소는 `DioException`으로 감싸 던지므로 [AppException.from]으로 풀어서 본다.
bool isSignupAlreadyCompletedError(Object error) {
  final exception = AppException.from(error);
  return exception is ApiException &&
      exception.errorCode == ErrorCode.stateConflict;
}
