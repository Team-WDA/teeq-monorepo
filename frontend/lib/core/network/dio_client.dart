import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/network/network_log_interceptor.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/network/api_error_interceptor.dart';
import 'package:teeq/core/network/auth_interceptor.dart';
import 'package:teeq/core/network/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

/// 앱 전체에서 공유하는 Dio 인스턴스. base URL은 [AppConfig]에서 가져온다.
/// 인터셉터 순서: [NetworkLogInterceptor]가 원본 요청·응답·오류를 기록하고,
/// [ApiErrorInterceptor]가 오류를 변환한 뒤 [AuthInterceptor]가 판단한다.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(_baseOptions(ref.watch(appConfigProvider)));
  dio.interceptors.addAll([
    NetworkLogInterceptor(store: ref.watch(debugConsoleStoreProvider.notifier)),
    ApiErrorInterceptor(logger: ref.watch(appLoggerProvider)),
    AuthInterceptor(
      logger: ref.watch(appLoggerProvider),
      dio: dio,
      tokenStorage: ref.watch(tokenStorageProvider),
      tokenRefresher: ref.watch(tokenRefresherProvider),
      // 빌드 시점이 아니라 세션이 끝날 때 읽어, provider 간 순환을 만들지 않는다.
      onSessionExpired: () => ref.read(authSessionProvider).signOut(),
    ),
  ]);
  return dio;
}

/// 토큰 갱신 전용 Dio. [AuthInterceptor] 없이 [ApiErrorInterceptor]만 두어 갱신 요청이
/// 인증 인터셉터를 다시 타지 않게 한다.
@Riverpod(keepAlive: true)
Dio plainDio(Ref ref) {
  final dio = Dio(_baseOptions(ref.watch(appConfigProvider)));
  dio.interceptors.addAll([
    NetworkLogInterceptor(store: ref.watch(debugConsoleStoreProvider.notifier)),
    ApiErrorInterceptor(logger: ref.watch(appLoggerProvider)),
  ]);
  return dio;
}

@Riverpod(keepAlive: true)
TokenRefresher tokenRefresher(Ref ref) =>
    DioTokenRefresher(ref.watch(plainDioProvider));

BaseOptions _baseOptions(AppConfig config) => BaseOptions(
  baseUrl: config.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
);
