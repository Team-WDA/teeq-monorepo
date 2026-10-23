import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/auth/data/firebase_social_credential_provider.dart';

void main() {
  group('isCancellation', () {
    test('canceled와 web-context-canceled는 사용자 취소로 본다', () {
      for (final code in ['canceled', 'web-context-canceled']) {
        expect(
          FirebaseSocialCredentialProvider.isCancellation(
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
          FirebaseSocialCredentialProvider.isCancellation(
            FirebaseAuthException(code: code),
          ),
          isFalse,
          reason: code,
        );
      }
    });
  });
}
