import 'package:teeq/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.validate', () {
    test('validate_allPresent_doesNotThrow', () {
      const config = AppConfig(
        apiBaseUrl: 'https://api.example.test',
        appleServiceId: 'kr.co.teeq.app.service',
        appleRedirectUri: 'https://api.example.test/api/auth/apple/callback',
      );

      expect(config.validate, returnsNormally);
    });

    test('validate_missingAppleKeys_listsAllMissingKeys', () {
      const config = AppConfig(
        apiBaseUrl: '',
        appleServiceId: '',
        appleRedirectUri: '',
      );

      expect(
        config.validate,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('API_BASE_URL'),
              contains('APPLE_SERVICE_ID'),
              contains('APPLE_REDIRECT_URI'),
            ),
          ),
        ),
      );
    });
  });
}
