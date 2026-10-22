import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teeq/core/debug_console/developer_mode_storage.dart';

/// 개발자 모드 플래그를 기기의 보안 저장소에 `'true'`/`'false'` 문자열로 둔다.
final class SecureDeveloperModeStorage implements DeveloperModeStorage {
  SecureDeveloperModeStorage(this._storage);

  static const enabledKey = 'developer_mode_enabled';

  final FlutterSecureStorage _storage;

  /// `'true'`일 때만 true. 읽기가 어떤 예외로든 실패하면 꺼진 상태로 본다.
  @override
  Future<bool> readEnabled() async {
    try {
      return await _storage.read(key: enabledKey) == 'true';
    } on Object {
      return false;
    }
  }

  @override
  Future<void> writeEnabled(bool enabled) =>
      _storage.write(key: enabledKey, value: enabled.toString());
}
