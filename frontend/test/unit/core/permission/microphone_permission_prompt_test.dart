import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/permission/app_permission_status.dart';
import 'package:teeq/core/permission/microphone_permission_prompt.dart';

import '../../../support/fake_app_permission_gateway.dart';

void main() {
  group('MicrophonePermissionPrompt.requestOnceIfNeeded', () {
    test('처음 호출이고 미허용이면 한 번 요청하고 물어봤다고 기록한다', () async {
      final gateway = FakeAppPermissionGateway();
      final storage = FakeMicrophonePromptStorage();
      final prompt = MicrophonePermissionPrompt(
        gateway: gateway,
        storage: storage,
      );

      await prompt.requestOnceIfNeeded();

      expect(gateway.requestCount, 1);
      expect(storage.prompted, isTrue);
    });

    test('두 번째 호출은 다시 요청하지 않는다', () async {
      final gateway = FakeAppPermissionGateway();
      final prompt = MicrophonePermissionPrompt(
        gateway: gateway,
        storage: FakeMicrophonePromptStorage(),
      );

      await prompt.requestOnceIfNeeded();
      await prompt.requestOnceIfNeeded();

      expect(gateway.requestCount, 1);
    });

    test('이미 허용되어 있으면 요청하지 않는다', () async {
      final gateway = FakeAppPermissionGateway(
        initialStatus: AppPermissionStatus.granted,
      );
      final prompt = MicrophonePermissionPrompt(
        gateway: gateway,
        storage: FakeMicrophonePromptStorage(),
      );

      await prompt.requestOnceIfNeeded();

      expect(gateway.requestCount, 0);
    });

    test('요청 결과가 거절이어도 예외 없이 물어봤다고 기록한다', () async {
      final gateway = FakeAppPermissionGateway(
        requestResult: AppPermissionStatus.permanentlyDenied,
      );
      final storage = FakeMicrophonePromptStorage();
      final prompt = MicrophonePermissionPrompt(
        gateway: gateway,
        storage: storage,
      );

      await prompt.requestOnceIfNeeded();

      expect(gateway.requestCount, 1);
      expect(storage.prompted, isTrue);
    });
  });
}
