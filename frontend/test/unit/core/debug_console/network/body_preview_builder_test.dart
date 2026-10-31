import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/body_preview.dart';
import 'package:teeq/core/debug_console/network/body_preview_builder.dart';

void main() {
  test('returns null for null data', () {
    expect(BodyPreviewBuilder.fromData(null), isNull);
  });

  test('keeps an empty string as an empty untruncated preview', () {
    final preview = BodyPreviewBuilder.fromData('');

    expect(preview, isNotNull);
    expect(preview!.text, isEmpty);
    expect(preview.isTruncated, isFalse);
  });

  test('passes a string through', () {
    expect(BodyPreviewBuilder.fromData('plain')!.text, 'plain');
  });

  test('pretty prints a map as indented JSON', () {
    final preview = BodyPreviewBuilder.fromData({
      'nickname': '철수',
      'tags': [1, 2],
    });

    expect(preview!.text, contains('  "nickname": "철수"'));
    expect(preview.text, contains('"tags": ['));
  });

  test('replaces values JSON cannot encode with their string form', () {
    final preview = BodyPreviewBuilder.fromData({'value': Object()});

    expect(preview!.text, contains("Instance of 'Object'"));
  });

  test('truncates a body over the maximum length', () {
    final preview = BodyPreviewBuilder.fromData('a' * 204800);

    expect(preview!.isTruncated, isTrue);
    expect(preview.originalLength, 204800);
    expect(preview.text.length, maxBodyPreviewLength);
  });

  test('summarizes FormData with field values and file names only', () {
    final formData = FormData.fromMap({
      'nickname': '철수',
      'image': MultipartFile.fromBytes([1, 2, 3], filename: 'a.png'),
    });

    final text = BodyPreviewBuilder.fromData(formData)!.text;

    expect(text, contains('FormData'));
    expect(text, contains('nickname=철수'));
    expect(text, contains('a.png'));
    expect(text, contains('3바이트'));
    expect(text, isNot(contains('[1, 2, 3]')));
  });

  test('summarizes binary data by length', () {
    expect(BodyPreviewBuilder.fromData(Uint8List(10))!.text, '[바이너리 10바이트]');
    expect(BodyPreviewBuilder.fromData(<int>[1, 2, 3])!.text, '[바이너리 3바이트]');
  });

  test('falls back to the string form for other objects', () {
    expect(BodyPreviewBuilder.fromData(42)!.text, '42');
  });

  group('token masking', () {
    test('masks token values in nested maps and keeps other values', () {
      final text = BodyPreviewBuilder.fromData({
        'connection': {'token': 'secret', 'livekitUrl': 'wss://x'},
      })!.text;

      expect(text, isNot(contains('secret')));
      expect(text, contains('"token": "***"'));
      expect(text, contains('"livekitUrl": "wss://x"'));
    });

    test('masks keys containing token regardless of case', () {
      final text = BodyPreviewBuilder.fromData({
        'Token': 'a1',
        'accessToken': 'b2',
        'refreshToken': 'c3',
      })!.text;

      expect(text, isNot(contains('a1')));
      expect(text, isNot(contains('b2')));
      expect(text, isNot(contains('c3')));
    });

    test('masks maps inside lists', () {
      final text = BodyPreviewBuilder.fromData([
        {'token': 'secret'},
      ])!.text;

      expect(text, isNot(contains('secret')));
      expect(text, contains('***'));
    });

    test('masks a JSON string body', () {
      final text = BodyPreviewBuilder.fromData(
        '{"connection":{"token":"secret","livekitUrl":"wss://x"}}',
      )!.text;

      expect(text, isNot(contains('secret')));
      expect(text, contains('wss://x'));
    });

    test('returns a string without token keys byte for byte', () {
      const original = '{"a":1,  "b" : [2]}';

      expect(BodyPreviewBuilder.fromData(original)!.text, original);
    });

    test('returns a non-JSON string unchanged', () {
      expect(BodyPreviewBuilder.fromData('token=secret')!.text, 'token=secret');
    });

    test('keeps a map without token keys identical to the plain output', () {
      final data = {
        'nickname': '철수',
        'tags': [1, 2],
      };

      expect(
        BodyPreviewBuilder.fromData(data)!.text,
        const JsonEncoder.withIndent('  ').convert(data),
      );
    });
  });
}
