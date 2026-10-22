import 'package:dio/dio.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/network/token_refresher.dart';

/// 요청에 Authorization을 붙이고, `EXPIRED_TOKEN`이면 토큰을 한 번 갱신해 원 요청을 한 번 재시도한다.
/// `ApiErrorInterceptor` 다음에 두어 `DioException.error`에 담긴 [ApiException]으로 판단한다.
/// 동시에 만료된 요청들은 진행 중인 갱신 하나를 함께 기다린다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._tokenStorage,
    required this._tokenRefresher,
    required this._onSessionExpired,
    required this._logger,
  });

  /// 재시도한 요청 표시. 이 표시가 있는 요청은 다시 갱신하지 않는다.
  static const retriedKey = 'authRetried';

  static const _authorizationHeader = 'Authorization';
  static const _bearerPrefix = 'Bearer ';
  static const _logoutPath = '/api/auth/logout';
  static const _signupPath = '/api/members';

  /// Authorization을 붙이지 않고 갱신 대상에서도 빼는 경로(메서드 무관).
  static const _exemptPaths = {
    '/api/auth/login',
    '/api/auth/social-login',
    '/api/auth/refresh',
  };

  /// 갱신 요청이 이 코드로 실패하면 세션을 끝낸다(저장소 비우기, 로그아웃).
  static const _sessionEndingCodes = {
    ErrorCode.invalidRefreshToken,
    ErrorCode.unauthenticated,
    ErrorCode.expiredToken,
  };

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final TokenRefresher _tokenRefresher;
  final Future<void> Function() _onSessionExpired;
  final AppLogger _logger;

  /// 가장 최근 갱신. 진행 중이면 공유하고, 성공했으면 늦게 도착한 같은 토큰의 요청도 재사용한다.
  _RefreshAttempt? _latestRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isExempt(options)) {
      final tokens = await _tokenStorage.read();
      if (tokens != null) {
        options.headers[_authorizationHeader] =
            '$_bearerPrefix${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRefresh(err)) {
      handler.next(err);
      return;
    }

    final AuthTokens? tokens;
    try {
      tokens = await _tokensForRetry(err.requestOptions);
    } on DioException catch (refreshError) {
      // 갱신 실패는 원래의 EXPIRED_TOKEN이 아니라 갱신 오류 그대로 전한다.
      handler.next(refreshError);
      return;
    } on Object catch (error, stackTrace) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: AppException.from(error),
          stackTrace: stackTrace,
        ),
      );
      return;
    }
    if (tokens == null) {
      // 저장된 토큰이 없거나(이미 로그아웃) 갱신 도중 세션이 바뀌었다. 원래 오류를 그대로 넘긴다.
      handler.next(err);
      return;
    }

    // fetch는 인터셉터 체인을 처음부터 다시 타므로 재시도 실패도 ApiErrorInterceptor가
    // 한 번 변환한 DioException으로 돌아온다.
    try {
      final response = await _dio.fetch<dynamic>(
        _retryOptions(err.requestOptions, tokens.accessToken),
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isExempt(RequestOptions options) {
    final path = options.uri.path;
    return _exemptPaths.contains(path) ||
        (path == _signupPath && options.method.toUpperCase() == 'POST');
  }

  bool _shouldRefresh(DioException err) {
    final cause = err.error;
    final options = err.requestOptions;
    return cause is ApiException &&
        cause.errorCode == ErrorCode.expiredToken &&
        options.extra[retriedKey] != true &&
        options.uri.path != _logoutPath &&
        !_isExempt(options);
  }

  /// 재시도에 쓸 토큰. 저장된 토큰이 없거나 갱신 도중 세션이 바뀌었으면 null.
  /// 확인과 갱신 시작 사이에 await가 없어, 동시에 도착한 요청도 갱신을 한 번만 시작한다.
  Future<AuthTokens?> _tokensForRetry(RequestOptions options) async {
    final requestAccessToken = _requestAccessToken(options);
    final stored = await _tokenStorage.read();
    if (stored == null) {
      return null;
    }
    if (stored.accessToken != requestAccessToken) {
      // 다른 요청이 이미 갱신했다. 갱신 없이 새 토큰으로 재시도한다.
      return stored;
    }
    final latest = _latestRefresh;
    if (latest != null && latest.expiredAccessToken == requestAccessToken) {
      return latest.result;
    }
    final attempt = _RefreshAttempt(
      expiredAccessToken: stored.accessToken,
      result: _refreshAndSave(stored),
    );
    _latestRefresh = attempt;
    return attempt.result;
  }

  /// 갱신한 토큰을 저장하고 돌려준다. 갱신 도중 로그아웃이나 다른 회원 로그인으로 세션이
  /// 바뀌었으면 저장하지 않고 null을 돌려준다(호출 측은 원래 오류를 그대로 넘긴다).
  Future<AuthTokens?> _refreshAndSave(AuthTokens expiredTokens) async {
    try {
      final tokens = await _tokenRefresher.refresh(expiredTokens.refreshToken);
      if (!await _isCurrentSession(expiredTokens)) {
        return null;
      }
      await _tokenStorage.save(tokens);
      return tokens;
    } on Object catch (error) {
      // 실패한 갱신은 공유하지 않는다. 다음 요청이 다시 시도할 수 있다.
      if (_latestRefresh?.expiredAccessToken == expiredTokens.accessToken) {
        _latestRefresh = null;
      }
      // 네트워크·5xx 실패는 토큰을 그대로 두고, 인증 오류일 때만 세션을 끝낸다.
      // 이미 바뀐 세션(새 회원의 토큰)은 지우지 않는다.
      if (error is DioException &&
          _endsSession(error.error) &&
          await _isCurrentSession(expiredTokens)) {
        await _expireSession();
      }
      rethrow;
    }
  }

  /// 이 갱신을 시작한 세션이 아직 저장소의 현재 세션인지.
  Future<bool> _isCurrentSession(AuthTokens expiredTokens) async =>
      (await _tokenStorage.read())?.accessToken == expiredTokens.accessToken;

  bool _endsSession(Object? cause) =>
      cause is ApiException && _sessionEndingCodes.contains(cause.errorCode);

  /// 저장소를 비우고 세션 종료를 알린다. 실패해도 갱신 오류 전달을 막지 않도록 기록만 한다.
  Future<void> _expireSession() async {
    try {
      await _tokenStorage.clear();
    } on Object catch (error) {
      _logger.log(
        '토큰 삭제 실패: $error',
        name: 'AuthInterceptor',
        level: AppLogLevel.error,
      );
    }
    try {
      await _onSessionExpired();
    } on Object catch (error) {
      _logger.log(
        '세션 종료 처리 실패: $error',
        name: 'AuthInterceptor',
        level: AppLogLevel.error,
      );
    }
  }

  String? _requestAccessToken(RequestOptions options) {
    final header = options.headers[_authorizationHeader];
    if (header is String && header.startsWith(_bearerPrefix)) {
      return header.substring(_bearerPrefix.length);
    }
    return null;
  }

  RequestOptions _retryOptions(RequestOptions options, String accessToken) {
    final data = options.data;
    return options.copyWith(
      // 전송을 마친 FormData는 다시 쓸 수 없어 복제본으로 재시도한다.
      data: data is FormData ? data.clone() : data,
      headers: {
        ...options.headers,
        _authorizationHeader: '$_bearerPrefix$accessToken',
      },
      extra: {...options.extra, retriedKey: true},
    );
  }
}

/// 한 번의 갱신과, 그 갱신이 대체하는 만료 access 토큰.
final class _RefreshAttempt {
  const _RefreshAttempt({
    required this.expiredAccessToken,
    required this.result,
  });

  final String expiredAccessToken;

  /// 갱신 결과. 갱신 도중 세션이 바뀌었으면 null.
  final Future<AuthTokens?> result;
}
