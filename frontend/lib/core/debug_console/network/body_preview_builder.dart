import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:teeq/core/debug_console/body_preview.dart';

/// dio 요청·응답 본문을 디버그 콘솔에 보여 줄 [BodyPreview]로 바꾼다.
///
/// 바이너리와 파일 내용은 저장하지 않고 길이만 남기며, 결과는 모두 길이 상한을 거친다.
abstract final class BodyPreviewBuilder {
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent(
    '  ',
    _encodeUnsupportedValue,
  );

  static const String _maskedValue = '***';

  static BodyPreview? fromData(Object? data) {
    if (data == null) {
      return null;
    }
    return BodyPreview.fromText(_describe(data));
  }

  static String _describe(Object data) {
    if (data is String) {
      return _maskJsonString(data);
    }
    if (data is FormData) {
      return _describeFormData(data);
    }
    if (data is List<int>) {
      return '[바이너리 ${data.length}바이트]';
    }
    if (data is Map || data is List) {
      return _prettyEncoder.convert(_maskTokens(data).value);
    }
    return data.toString();
  }

  /// JSON 문자열에서 토큰 값을 가린다. 가릴 것이 없거나 JSON이 아니면 원문을 그대로 돌려준다.
  static String _maskJsonString(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      return text;
    }
    final masked = _maskTokens(decoded);
    return masked.didMask ? _prettyEncoder.convert(masked.value) : text;
  }

  /// 이름에 `token`이 들어간 키의 값을 [_maskedValue]로 바꾼 사본과 가림 여부를 돌려준다.
  static ({Object? value, bool didMask}) _maskTokens(Object? value) {
    if (value is Map) {
      var didMask = false;
      final result = <Object?, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is String && key.toLowerCase().contains('token')) {
          result[key] = _maskedValue;
          didMask = true;
          continue;
        }
        final masked = _maskTokens(entry.value);
        didMask = didMask || masked.didMask;
        result[key] = masked.value;
      }
      return (value: result, didMask: didMask);
    }
    if (value is List) {
      var didMask = false;
      final result = <Object?>[];
      for (final element in value) {
        final masked = _maskTokens(element);
        didMask = didMask || masked.didMask;
        result.add(masked.value);
      }
      return (value: result, didMask: didMask);
    }
    return (value: value, didMask: false);
  }

  static String _describeFormData(FormData formData) {
    final lines = <String>['FormData', 'fields:'];
    for (final field in formData.fields) {
      lines.add('  ${field.key}=${field.value}');
    }
    lines.add('files:');
    for (final file in formData.files) {
      lines.add(
        '  ${file.key} (${file.value.filename ?? '이름 없음'}, '
        '${file.value.length}바이트)',
      );
    }
    return lines.join('\n');
  }

  /// JSON으로 바꿀 수 없는 값은 문자열 표현으로 대신한다.
  static Object? _encodeUnsupportedValue(Object? value) => value.toString();
}
