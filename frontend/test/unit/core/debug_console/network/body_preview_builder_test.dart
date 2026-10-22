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
}
