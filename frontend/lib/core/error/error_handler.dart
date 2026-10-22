import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_session.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_presentation.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/router/app_router.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/error_page_arguments.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';

part 'error_handler.g.dart';

@Riverpod(keepAlive: true)
ErrorHandler errorHandler(Ref ref) => ErrorHandler(ref);

/// 앱의 오류 표시를 맡는 중앙 한 곳.
///
/// 진입점 계약: 자동 라우팅(ProviderObserver)은 없다. 아래 두 곳에서만
/// `ref.read(errorHandlerProvider).handle(error)`를 호출한다.
/// - 쓰기 작업: Notifier 메서드의 catch 또는 `AsyncValue.guard` 실패 처리
/// - 화면: `ref.listen(provider, (previous, next) { ... })` 안에서 `next`가 `AsyncError`일 때
///   (앱 시작·초기 로딩 실패는 `blocking: true`). `build()`나 `when(error:)` 안에서는
///   호출하지 않는다. 빌드 중에 provider 상태 변경과 라우팅이 일어나 예외가 난다.
///
/// [handle]은 [AppException], 인터셉터가 감싼 [DioException], 임의의 객체를 모두 받는다.
class ErrorHandler {
  ErrorHandler(this._ref);

  final Ref _ref;

  void handle(Object error, {bool blocking = false}) {
    // 사용자가 취소한 요청은 오류가 아니다.
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return;
    }
    final exception = AppException.from(error);
    // developerMessage와 원인은 로그에만 남기고 화면에는 userMessage만 쓴다.
    final status = exception is ApiException ? exception.httpStatus : null;
    final isClientError = status != null && status >= 400 && status < 500;
    _ref
        .read(appLoggerProvider)
        .log(
          exception is ApiException
              ? '$exception developerMessage: ${exception.developerMessage}'
              : '$exception',
          name: 'ErrorHandler',
          level: isClientError ? AppLogLevel.warning : AppLogLevel.error,
          error: error,
        );

    switch (classify(exception, blocking: blocking)) {
      case ErrorPresentation.toast:
        _ref.read(toastControllerProvider.notifier).show(exception.userMessage);
      case ErrorPresentation.errorPage:
        _showErrorPage(exception.userMessage);
      case ErrorPresentation.authentication:
        unawaited(_ref.read(authSessionProvider).signOut());
    }
  }

  void _showErrorPage(String message) {
    final router = _ref.read(appRouterProvider);
    final configuration = router.routerDelegate.currentConfiguration;
    final isOnErrorPage = configuration.uri.path == AppRoutes.error;
    final extra = configuration.extra;
    // 이미 오류 페이지면 기존 retryLocation을 유지해 "다시 시도" 순환을 막는다.
    final currentLocation = configuration.uri.toString();
    final retryLocation = isOnErrorPage
        ? (extra is ErrorPageArguments ? extra.retryLocation : AppRoutes.home)
        : (currentLocation.isEmpty ? AppRoutes.home : currentLocation);
    router.go(
      AppRoutes.error,
      extra: ErrorPageArguments(message: message, retryLocation: retryLocation),
    );
  }
}
