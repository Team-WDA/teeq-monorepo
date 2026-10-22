import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/network/api_error_interceptor.dart';
import 'package:teeq/core/network/auth_interceptor.dart';
import 'package:teeq/core/network/token_refresher.dart';

import '../../../support/fake_token_storage.dart';
import '../../../support/scripted_http_client_adapter.dart';

const _baseUrl = 'https://api.example.test';
const _refreshPath = '/api/auth/refresh';
const _oldTokens = AuthTokens(
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
);
const _newTokens = AuthTokens(
  accessToken: 'new-access',
  refreshToken: 'new-refresh',
);

ScriptedReply _error(int statusCode, String errorCode, {Duration? delay}) =>
    ScriptedReply.json(statusCode, {
      'errorCode': errorCode,
      'errorMessage': '상세',
    }, delay: delay ?? Duration.zero);

ScriptedReply _ok([Object? body]) => ScriptedReply.json(200, body ?? {});

ScriptedReply _refreshed({Duration delay = Duration.zero}) =>
    ScriptedReply.json(200, {
      'accessToken': _newTokens.accessToken,
      'refreshToken': _newTokens.refreshToken,
    }, delay: delay);

ScriptedReply _connectionFailure() => ScriptedReply.failure(
  (options) =>
      DioException.connectionError(requestOptions: options, reason: '연결 실패'),
);

/// 실제 구성과 같은 순서(ApiErrorInterceptor → AuthInterceptor)로 묶은 테스트 환경.
class _Harness {
  _Harness({AuthTokens? storedTokens, Object? clearError})
    : storage = FakeTokenStorage(
        storedTokens: storedTokens,
        clearError: clearError,
      ) {
    final plainDio = Dio(BaseOptions(baseUrl: _baseUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(ApiErrorInterceptor(logger: logger));
    dio = Dio(BaseOptions(baseUrl: _baseUrl))..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      ApiErrorInterceptor(logger: logger),
      AuthInterceptor(
        logger: logger,
        dio: dio,
        tokenStorage: storage,
        tokenRefresher: DioTokenRefresher(plainDio),
        onSessionExpired: () async => sessionExpiredCount++,
      ),
    ]);
  }

  final ScriptedHttpClientAdapter adapter = ScriptedHttpClientAdapter();
  final List<AppLogEntry> logEntries = [];
  late final AppLogger logger = AppLogger(onEntry: logEntries.add);
  final FakeTokenStorage storage;
  late final Dio dio;
  int sessionExpiredCount = 0;

  List<String?> authorizationsTo(String path) => adapter
      .requestsTo(path)
      .map((options) => options.headers['Authorization'] as String?)
      .toList();
}

Future<DioException> _captureError(Future<Object?> call) async {
  try {
    await call;
  } on DioException catch (error) {
    return error;
  }
  fail('DioException이 발생해야 한다');
}

void main() {
  test('request_attachesBearerWhenTokenExists', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter.on('/api/members/me', [_ok()]);

    await harness.dio.get<dynamic>('/api/members/me');

    expect(harness.authorizationsTo('/api/members/me'), ['Bearer old-access']);
  });

  test('request_exemptPaths_haveNoAuthorizationHeader', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter
      ..on('/api/auth/login', [_ok()])
      ..on('/api/auth/social-login', [_ok()])
      ..on(_refreshPath, [_ok()])
      ..on('/api/members', [_ok(), _ok()]);

    await harness.dio.post<dynamic>('/api/auth/login');
    await harness.dio.post<dynamic>('/api/auth/social-login');
    await harness.dio.post<dynamic>(_refreshPath);
    await harness.dio.post<dynamic>('/api/members');
    // POST만 면제이므로 같은 경로라도 GET에는 붙는다.
    await harness.dio.get<dynamic>('/api/members');

    expect(harness.authorizationsTo('/api/auth/login'), [null]);
    expect(harness.authorizationsTo('/api/auth/social-login'), [null]);
    expect(harness.authorizationsTo(_refreshPath), [null]);
    expect(harness.authorizationsTo('/api/members'), [
      null,
      'Bearer old-access',
    ]);
  });

  test('request_appVersionCheck_hasNoAuthorizationHeader', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter.on('/api/app-versions/check', [_ok()]);

    await harness.dio.get<dynamic>('/api/app-versions/check');

    expect(harness.authorizationsTo('/api/app-versions/check'), [null]);
  });

  test('expiredToken_refreshesOnceAndRetriesOnceWithNewToken', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter
      ..on('/api/members/me', [
        _error(401, 'EXPIRED_TOKEN'),
        _ok({'nickname': '티큐'}),
      ])
      ..on(_refreshPath, [_refreshed()]);

    final response = await harness.dio.get<dynamic>('/api/members/me');

    expect(response.data, {'nickname': '티큐'});
    expect(harness.adapter.callCount(_refreshPath), 1);
    expect(harness.adapter.requestsTo(_refreshPath).single.data, {
      'refreshToken': 'old-refresh',
    });
    expect(harness.authorizationsTo('/api/members/me'), [
      'Bearer old-access',
      'Bearer new-access',
    ]);
    expect(
      harness.adapter.requestsTo('/api/members/me').last.extra['authRetried'],
      isTrue,
    );
    expect(harness.storage.storedTokens, _newTokens);
    expect(harness.sessionExpiredCount, 0);
  });

  test('concurrentExpiredRequests_refreshOnlyOnce', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    const paths = ['/api/first', '/api/second', '/api/third'];
    for (final path in paths) {
      harness.adapter.on(path, [_error(401, 'EXPIRED_TOKEN'), _ok()]);
    }
    harness.adapter.on(_refreshPath, [
      _refreshed(delay: const Duration(milliseconds: 50)),
    ]);

    final responses = await Future.wait(
      paths.map((path) => harness.dio.get<dynamic>(path)),
    );

    expect(responses.map((response) => response.statusCode), [200, 200, 200]);
    expect(harness.adapter.callCount(_refreshPath), 1);
    for (final path in paths) {
      expect(harness.authorizationsTo(path).last, 'Bearer new-access');
    }
    expect(harness.storage.storedTokens, _newTokens);
  });

  test(
    'lateExpiredRequest_usesAlreadyRefreshedTokenWithoutRefreshing',
    () async {
      // 이 요청이 old 토큰으로 나간 사이 다른 요청이 이미 갱신을 마친 상황.
      final harness = _Harness(storedTokens: _oldTokens);
      harness.adapter.on('/api/members/me', [
        _error(401, 'EXPIRED_TOKEN', delay: const Duration(milliseconds: 20)),
        _ok(),
      ]);

      final pending = harness.dio.get<dynamic>('/api/members/me');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      harness.storage.storedTokens = _newTokens;
      final response = await pending;

      expect(response.statusCode, 200);
      expect(harness.adapter.callCount(_refreshPath), 0);
      expect(harness.authorizationsTo('/api/members/me'), [
        'Bearer old-access',
        'Bearer new-access',
      ]);
    },
  );

  test('unauthenticated_isNotRefreshed_andPassesThrough', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter.on('/api/members/me', [_error(401, 'UNAUTHENTICATED')]);

    final error = await _captureError(
      harness.dio.get<dynamic>('/api/members/me'),
    );

    expect((error.error as ApiException).errorCode, ErrorCode.unauthenticated);
    expect(harness.adapter.callCount(_refreshPath), 0);
    expect(harness.adapter.callCount('/api/members/me'), 1);
    expect(harness.storage.storedTokens, _oldTokens);
  });

  test(
    'tokenStorageClearFailure_isLoggedAsErrorAndSessionStillExpires',
    () async {
      final harness = _Harness(
        storedTokens: _oldTokens,
        clearError: StateError('삭제 실패'),
      );
      harness.adapter
        ..on('/api/members/me', [_error(401, 'EXPIRED_TOKEN')])
        ..on(_refreshPath, [_error(401, 'INVALID_REFRESH_TOKEN')]);

      await _captureError(harness.dio.get<dynamic>('/api/members/me'));

      final failureLogs = harness.logEntries.where(
        (entry) => entry.name == 'AuthInterceptor',
      );
      expect(failureLogs, hasLength(1));
      expect(failureLogs.single.level, AppLogLevel.error);
      expect(failureLogs.single.message, contains('토큰 삭제 실패'));
      expect(harness.sessionExpiredCount, 1);
    },
  );

  test(
    'refreshFailsWithInvalidRefreshToken_clearsStorageAndCallsSessionExpired',
    () async {
      final harness = _Harness(storedTokens: _oldTokens);
      harness.adapter
        ..on('/api/members/me', [_error(401, 'EXPIRED_TOKEN')])
        ..on(_refreshPath, [_error(401, 'INVALID_REFRESH_TOKEN')]);

      final error = await _captureError(
        harness.dio.get<dynamic>('/api/members/me'),
      );

      expect(
        (error.error as ApiException).errorCode,
        ErrorCode.invalidRefreshToken,
      );
      expect(harness.storage.clearCount, 1);
      expect(harness.storage.storedTokens, isNull);
      expect(harness.sessionExpiredCount, 1);
      expect(harness.adapter.callCount('/api/members/me'), 1);
    },
  );

  test(
    'refreshFailsWithNetworkError_keepsTokensAndRethrowsNetworkError',
    () async {
      final harness = _Harness(storedTokens: _oldTokens);
      harness.adapter
        ..on('/api/members/me', [_error(401, 'EXPIRED_TOKEN')])
        ..on(_refreshPath, [_connectionFailure()]);

      final error = await _captureError(
        harness.dio.get<dynamic>('/api/members/me'),
      );

      expect(error.error, isA<NetworkException>());
      expect(harness.storage.storedTokens, _oldTokens);
      expect(harness.storage.clearCount, 0);
      expect(harness.sessionExpiredCount, 0);
      expect(harness.adapter.callCount('/api/members/me'), 1);
    },
  );

  test(
    'refreshFailsWithServerError_keepsTokensAndRethrowsServerError',
    () async {
      final harness = _Harness(storedTokens: _oldTokens);
      harness.adapter
        ..on('/api/members/me', [_error(401, 'EXPIRED_TOKEN')])
        ..on(_refreshPath, [_error(500, 'INTERNAL_SERVER_ERROR')]);

      final error = await _captureError(
        harness.dio.get<dynamic>('/api/members/me'),
      );

      final exception = error.error as ApiException;
      expect(exception.errorCode, ErrorCode.internalServerError);
      expect(exception.httpStatus, 500);
      expect(harness.storage.storedTokens, _oldTokens);
      expect(harness.sessionExpiredCount, 0);
    },
  );

  test(
    'retriedRequestFailsAgainWithExpiredToken_doesNotRefreshAgain',
    () async {
      final harness = _Harness(storedTokens: _oldTokens);
      harness.adapter
        ..on('/api/members/me', [
          _error(401, 'EXPIRED_TOKEN'),
          _error(401, 'EXPIRED_TOKEN'),
        ])
        ..on(_refreshPath, [_refreshed()]);

      final error = await _captureError(
        harness.dio.get<dynamic>('/api/members/me'),
      );

      expect((error.error as ApiException).errorCode, ErrorCode.expiredToken);
      expect(harness.adapter.callCount(_refreshPath), 1);
      expect(harness.adapter.callCount('/api/members/me'), 2);
    },
  );

  group('세션이 갱신 도중 바뀌면 갱신 결과를 저장하지 않는다', () {
    const otherUserTokens = AuthTokens(
      accessToken: 'other-access',
      refreshToken: 'other-refresh',
    );

    Future<(_Harness, DioException)> expireDuringRefresh(
      AuthTokens? tokensAfterChange, {
      ScriptedReply? refreshReply,
    }) async {
      final harness = _Harness(storedTokens: _oldTokens);
      harness.adapter
        ..on('/api/members/me', [_error(401, 'EXPIRED_TOKEN')])
        ..on(_refreshPath, [
          refreshReply ?? _refreshed(delay: const Duration(milliseconds: 30)),
        ]);

      final pending = _captureError(
        harness.dio.get<dynamic>('/api/members/me'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      // 갱신이 진행 중일 때 로그아웃(null) 또는 다른 회원 로그인(새 토큰)이 일어났다.
      harness.storage.storedTokens = tokensAfterChange;
      return (harness, await pending);
    }

    test('signedOutDuringRefresh_doesNotSaveOrRetry', () async {
      final (harness, error) = await expireDuringRefresh(null);

      expect((error.error as ApiException).errorCode, ErrorCode.expiredToken);
      expect(harness.storage.storedTokens, isNull);
      expect(harness.storage.savedTokens, isNull);
      expect(harness.adapter.callCount('/api/members/me'), 1);
      expect(harness.storage.clearCount, 0);
      expect(harness.sessionExpiredCount, 0);
    });

    test('otherUserSignedInDuringRefresh_keepsOtherUserTokens', () async {
      final (harness, error) = await expireDuringRefresh(otherUserTokens);

      expect((error.error as ApiException).errorCode, ErrorCode.expiredToken);
      expect(harness.storage.storedTokens, otherUserTokens);
      expect(harness.storage.savedTokens, isNull);
      expect(harness.adapter.callCount('/api/members/me'), 1);
      expect(harness.storage.clearCount, 0);
      expect(harness.sessionExpiredCount, 0);
    });

    test(
      'otherUserSignedInDuringFailedRefresh_doesNotClearOrExpireSession',
      () async {
        final (harness, error) = await expireDuringRefresh(
          otherUserTokens,
          refreshReply: _error(
            401,
            'INVALID_REFRESH_TOKEN',
            delay: const Duration(milliseconds: 30),
          ),
        );

        expect(
          (error.error as ApiException).errorCode,
          ErrorCode.invalidRefreshToken,
        );
        expect(harness.storage.storedTokens, otherUserTokens);
        expect(harness.storage.clearCount, 0);
        expect(harness.sessionExpiredCount, 0);
      },
    );
  });

  test('logout401_isNotRefreshed', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter.on('/api/auth/logout', [_error(401, 'EXPIRED_TOKEN')]);

    final error = await _captureError(
      harness.dio.post<dynamic>('/api/auth/logout'),
    );

    expect((error.error as ApiException).errorCode, ErrorCode.expiredToken);
    expect(harness.authorizationsTo('/api/auth/logout'), ['Bearer old-access']);
    expect(harness.adapter.callCount(_refreshPath), 0);
    expect(harness.sessionExpiredCount, 0);
  });

  test('expiredToken_retriesMultipartRequestWithClonedFormData', () async {
    final harness = _Harness(storedTokens: _oldTokens);
    harness.adapter
      ..on('/api/members/me/profile-image', [
        _error(401, 'EXPIRED_TOKEN'),
        _ok({'profileImageUrl': 'https://image.example.test/a.jpg'}),
      ])
      ..on(_refreshPath, [_refreshed()]);
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        [1, 2, 3],
        filename: 'photo.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });

    final response = await harness.dio.put<dynamic>(
      '/api/members/me/profile-image',
      data: formData,
    );

    expect(response.statusCode, 200);
    expect(harness.adapter.callCount('/api/members/me/profile-image'), 2);
    expect(harness.authorizationsTo('/api/members/me/profile-image'), [
      'Bearer old-access',
      'Bearer new-access',
    ]);
  });
}
