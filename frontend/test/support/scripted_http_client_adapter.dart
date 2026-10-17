import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 어댑터가 한 번의 호출에 돌려줄 응답 또는 실패.
final class ScriptedReply {
  /// 상태 코드와 JSON 본문으로 응답한다. [delay]만큼 늦게 돌려준다.
  ScriptedReply.json(int statusCode, Object? body, {this.delay = Duration.zero})
    : _statusCode = statusCode,
      _body = body,
      _failure = null;

  /// 어댑터에서 [DioException]을 던진다(연결 실패, 타임아웃 등).
  ScriptedReply.failure(
    DioException Function(RequestOptions options) failure, {
    this.delay = Duration.zero,
  }) : _statusCode = null,
       _body = null,
       _failure = failure;

  final int? _statusCode;
  final Object? _body;
  final DioException Function(RequestOptions options)? _failure;
  final Duration delay;
}

/// 경로별로 미리 정한 응답을 순서대로 돌려주고 호출을 기록하는 테스트용 어댑터.
/// 정하지 않은 경로나 응답이 바닥난 경로를 호출하면 [StateError]를 던진다.
class ScriptedHttpClientAdapter implements HttpClientAdapter {
  final Map<String, List<ScriptedReply>> _replies = {};
  final Map<String, int> _callCounts = {};

  /// 받은 요청을 순서대로 기록한다(헤더 확인용).
  final List<RequestOptions> requests = [];

  /// [path]에 대한 응답을 호출 순서대로 덧붙인다.
  void on(String path, List<ScriptedReply> replies) {
    _replies.putIfAbsent(path, () => []).addAll(replies);
  }

  /// [path]가 호출된 횟수.
  int callCount(String path) => _callCounts[path] ?? 0;

  /// [path]로 들어온 요청들.
  List<RequestOptions> requestsTo(String path) =>
      requests.where((options) => options.uri.path == path).toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    requests.add(options);
    _callCounts[path] = callCount(path) + 1;

    final queue = _replies[path];
    if (queue == null || queue.isEmpty) {
      throw StateError('정하지 않은 호출: ${options.method} $path');
    }
    final reply = queue.removeAt(0);
    if (reply.delay > Duration.zero) {
      await Future<void>.delayed(reply.delay);
    }
    final failure = reply._failure;
    if (failure != null) {
      throw failure(options);
    }
    return ResponseBody.fromString(
      reply._body == null ? '' : jsonEncode(reply._body),
      reply._statusCode!,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
