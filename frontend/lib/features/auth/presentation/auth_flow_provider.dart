import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/token_storage.dart';
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
  );
}
