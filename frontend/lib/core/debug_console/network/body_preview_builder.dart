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

  static BodyPreview? fromData(Object? data) {
    if (data == null) {
      return null;
    }
    return BodyPreview.fromText(_describe(data));
  }

  static String _describe(Object data) {
    if (data is String) {
      return data;
    }
    if (data is FormData) {
      return _describeFormData(data);
    }
    if (data is List<int>) {
      return '[바이너리 ${data.length}바이트]';
    }
    if (data is Map || data is List) {
      return _prettyEncoder.convert(data);
    }
    return data.toString();
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
