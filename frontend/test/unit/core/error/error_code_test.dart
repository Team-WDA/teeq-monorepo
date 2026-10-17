import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_messages.dart';

const String _backendErrorCodePath =
    '../backend/src/main/java/kr/co/teeq/api/common/core/exception/ErrorCode.java';

void main() {
  test('모든 ErrorCode는 비어 있지 않은 사용자 문구를 가진다', () {
    for (final code in ErrorCode.values) {
      expect(code.userMessage, isNotEmpty, reason: code.serverName);
    }
  });

  group('fromServerName', () {
    test('알려진 이름은 해당 코드로 바꾼다', () {
      expect(ErrorCode.fromServerName('EXPIRED_TOKEN'), ErrorCode.expiredToken);
    });

    test('null이거나 모르는 이름은 unknown이다', () {
      expect(ErrorCode.fromServerName(null), ErrorCode.unknown);
      expect(ErrorCode.fromServerName('NOT_EXISTING'), ErrorCode.unknown);
      expect(ErrorCode.unknown.serverName, 'UNKNOWN');
    });
  });

  test('Dart serverName 집합이 BE ErrorCode.java 상수와 일치한다', () {
    final file = File(_backendErrorCodePath);
    final constantPattern = RegExp(r'^\s*([A-Z][A-Z0-9_]*)\(', multiLine: true);
    final backendNames = constantPattern
        .allMatches(file.readAsStringSync())
        .map((match) => match.group(1)!)
        .toSet();
    final dartNames = ErrorCode.values
        .map((code) => code.serverName)
        .where((name) => name != 'UNKNOWN')
        .toSet();

    expect(backendNames, hasLength(39));
    expect(dartNames, backendNames);
  }, skip: File(_backendErrorCodePath).existsSync() ? false : 'BE 파일 없음');
}
