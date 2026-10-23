import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_messages.dart';
import 'package:teeq/features/auth/data/firebase_auth_credential_provider.dart';

void main() {
  group('isCancellation', () {
    test('canceled와 web-context-canceled는 사용자 취소로 본다', () {
      for (final code in ['canceled', 'web-context-canceled']) {
        expect(
          FirebaseAuthCredentialProvider.isCancellation(
            FirebaseAuthException(code: code),
          ),
          isTrue,
          reason: code,
        );
      }
    });

    test('user-mismatch 등 다른 코드는 취소가 아니다', () {
      for (final code in ['user-mismatch', 'invalid-credential', 'failed']) {
        expect(
          FirebaseAuthCredentialProvider.isCancellation(
            FirebaseAuthException(code: code),
          ),
          isFalse,
          reason: code,
        );
      }
    });
  });

  group('mapEmailAuthException', () {
    AppException map(String code, {bool isCurrentPasswordCheck = false}) =>
        FirebaseAuthCredentialProvider.mapEmailAuthException(
          FirebaseAuthException(code: code),
          isCurrentPasswordCheck: isCurrentPasswordCheck,
        );

    test('자격 증명 오류 코드는 이메일 또는 비밀번호 오류로 바꾼다', () {
      for (final code in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
        'invalid-email',
      ]) {
        final exception = map(code);
        expect(exception, isA<InvalidCredentialsException>(), reason: code);
        expect(exception.userMessage, '이메일 또는 비밀번호가 올바르지 않아요.');
      }
    });

    test('비밀번호 변경 확인 중 자격 증명 오류는 현재 비밀번호 오류로 바꾼다', () {
      for (final code in ['invalid-credential', 'wrong-password']) {
        expect(
          map(code, isCurrentPasswordCheck: true),
          isA<InvalidCurrentPasswordException>(),
          reason: code,
        );
      }
    });

    test('email-already-in-use는 이미 사용 중인 이메일 오류다', () {
      final exception = map('email-already-in-use');
      expect(exception, isA<EmailAlreadyInUseException>());
      expect(exception.userMessage, '이미 사용 중인 이메일이에요.');
    });

    test('too-many-requests는 잠시 후 다시 시도 문구다', () {
      final exception = map('too-many-requests');
      expect(exception, isA<TooManyAttemptsException>());
      expect(exception.userMessage, '잠시 후 다시 시도해 주세요.');
    });

    test('network-request-failed는 기존 네트워크 문구다', () {
      final exception = map('network-request-failed');
      expect(exception, isA<NetworkException>());
      expect(exception.userMessage, '네트워크 연결을 확인하고 다시 시도해 주세요.');
    });

    test('weak-password, user-disabled 등 나머지는 일반 오류다', () {
      for (final code in ['weak-password', 'user-disabled', 'unknown-code']) {
        final exception = map(code);
        expect(exception, isA<UnexpectedException>(), reason: code);
        expect(exception.userMessage, unknownErrorMessage);
      }
    });
  });
}
