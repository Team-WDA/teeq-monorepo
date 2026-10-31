import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/permission/app_permission.dart';
import 'package:teeq/core/permission/app_permission_gateway.dart';
import 'package:teeq/core/permission/app_permission_status.dart';
import 'package:teeq/core/permission/permission_handler_gateway.dart';

part 'microphone_permission_prompt.g.dart';

/// 마이크 권한 요청을 이미 했는지 저장하는 계약. 테스트에서는 메모리 구현으로 바꾼다.
abstract interface class MicrophonePromptStorage {
  /// 이미 요청했으면 true. 없거나 읽을 수 없으면 false.
  Future<bool> hasPrompted();

  Future<void> markPrompted();
}

/// 요청 여부를 기기의 보안 저장소에 `'true'` 문자열로 둔다.
final class SecureMicrophonePromptStorage implements MicrophonePromptStorage {
  SecureMicrophonePromptStorage(this._storage);

  static const promptedKey = 'microphone_permission_prompted';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasPrompted() async {
    try {
      return await _storage.read(key: promptedKey) == 'true';
    } on Object {
      return false;
    }
  }

  @override
  Future<void> markPrompted() =>
      _storage.write(key: promptedKey, value: 'true');
}

/// 홈 진입 시 마이크 권한을 앱 생애에 한 번만 요청한다. 테스트에서 대체할 수 있게 일반 클래스로 둔다.
class MicrophonePermissionPrompt {
  MicrophonePermissionPrompt({required this._gateway, required this._storage});

  final AppPermissionGateway _gateway;
  final MicrophonePromptStorage _storage;

  /// 이미 요청했거나 허용 상태면 아무것도 하지 않는다. 요청 결과가 거절이어도 요청한 것으로 기록한다.
  Future<void> requestOnceIfNeeded() async {
    if (await _storage.hasPrompted()) {
      return;
    }
    final status = await _gateway.status(AppPermission.microphone);
    if (status != AppPermissionStatus.granted) {
      await _gateway.request(AppPermission.microphone);
    }
    await _storage.markPrompted();
  }
}

@Riverpod(keepAlive: true)
MicrophonePromptStorage microphonePromptStorage(Ref ref) =>
    SecureMicrophonePromptStorage(const FlutterSecureStorage());

@Riverpod(keepAlive: true)
MicrophonePermissionPrompt microphonePermissionPrompt(Ref ref) =>
    MicrophonePermissionPrompt(
      gateway: ref.watch(appPermissionGatewayProvider),
      storage: ref.watch(microphonePromptStorageProvider),
    );
