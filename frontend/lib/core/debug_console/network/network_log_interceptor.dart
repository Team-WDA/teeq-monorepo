import 'package:dio/dio.dart';
import 'package:teeq/core/debug_console/debug_console_store.dart';
import 'package:teeq/core/debug_console/network/body_preview_builder.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';

/// dio 요청과 응답을 디버그 콘솔 저장소에 기록한다.
///
/// 우리 인터셉터 중 가장 앞(`ApiErrorInterceptor`보다 앞)에 둔다. 오류 인터셉터는 목록 순서대로 실행되므로 `ApiErrorInterceptor`가
/// 변환하기 전의 원본 오류와, `AuthInterceptor`가 해결하기 전의 첫 응답(예: 만료 401)을 본다.
/// 토큰 갱신 후 재시도는 체인을 처음부터 다시 타서 별도 기록이 된다.
/// 개발자 모드가 꺼져 있으면 아무것도 하지 않는다.
class NetworkLogInterceptor extends Interceptor {
  NetworkLogInterceptor({required this._store, this._clock = DateTime.now});

  /// 요청 옵션에 심어, 응답·오류 때 어떤 기록인지 찾는 키.
  ///
  /// 재시도 요청은 `extra`를 복사하므로 원본 id를 물려받는다. 요청마다 항상 새 id로 덮어쓴다.
  static const entryIdKey = 'debugConsoleEntryId';

  final DebugConsoleStore _store;
  final DateTime Function() _clock;

  /// 아직 응답이나 오류를 받지 못한 기록.
  final Map<String, NetworkLogEntry> _pendingEntries = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra.remove(entryIdKey);
    if (_store.isCollecting) {
      final entry = NetworkLogEntry(
        id: _store.nextNetworkEntryId(),
        startedAt: _clock(),
        method: options.method,
        url: options.uri.toString(),
        requestHeaders: _stringifyHeaders(options.headers),
        requestBody: BodyPreviewBuilder.fromData(options.data),
      );
      options.extra[entryIdKey] = entry.id;
      _pendingEntries[entry.id] = entry;
      _store.recordNetworkStart(entry);
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _complete(response.requestOptions, response: response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _complete(
      err.requestOptions,
      response: err.response,
      errorDescription: _describeError(err),
    );
    handler.next(err);
  }

  void _complete(
    RequestOptions options, {
    Response<dynamic>? response,
    String? errorDescription,
  }) {
    final id = options.extra[entryIdKey];
    final pending = id is String ? _pendingEntries.remove(id) : null;
    if (pending == null) {
      return;
    }
    _store.recordNetworkCompletion(
      pending.copyWith(
        // 인증 인터셉터가 붙인 Authorization까지 보이도록 완료 시점의 헤더로 갱신한다.
        requestHeaders: _stringifyHeaders(options.headers),
        statusCode: response?.statusCode,
        responseHeaders: response == null
            ? null
            : {
                for (final header in response.headers.map.entries)
                  header.key: header.value.join(', '),
              },
        responseBody: BodyPreviewBuilder.fromData(response?.data),
        duration: _clock().difference(pending.startedAt),
        errorDescription: errorDescription,
      ),
    );
  }

  Map<String, String> _stringifyHeaders(Map<String, dynamic> headers) => {
    for (final header in headers.entries) header.key: '${header.value}',
  };

  String _describeError(DioException error) {
    final detail = error.message ?? error.error?.toString();
    return detail == null ? error.type.name : '${error.type.name}: $detail';
  }
}
