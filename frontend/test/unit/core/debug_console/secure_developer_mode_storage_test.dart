import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/debug_console/secure_developer_mode_storage.dart';

/// 메모리 맵으로 동작하고, 지정하면 읽기에서 예외를 던지는 가짜 보안 저장소.
class _FakeFlutterSecureStorage extends FlutterSecureStorage {
  _FakeFlutterSecureStorage({this.readError});

  final Object? readError;
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final error = readError;
    if (error != null) {
      throw error;
    }
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

void main() {
  test('reads true only when the stored value is the string true', () async {
    final secure = _FakeFlutterSecureStorage()
      ..values[SecureDeveloperModeStorage.enabledKey] = 'true';

    expect(await SecureDeveloperModeStorage(secure).readEnabled(), isTrue);
  });

  test('reads false when nothing or something else is stored', () async {
    final secure = _FakeFlutterSecureStorage();
    final storage = SecureDeveloperModeStorage(secure);

    expect(await storage.readEnabled(), isFalse);

    secure.values[SecureDeveloperModeStorage.enabledKey] = 'false';
    expect(await storage.readEnabled(), isFalse);

    secure.values[SecureDeveloperModeStorage.enabledKey] = 'garbage';
    expect(await storage.readEnabled(), isFalse);
  });

  test('reads false when the secure storage throws', () async {
    final storage = SecureDeveloperModeStorage(
      _FakeFlutterSecureStorage(readError: StateError('읽기 실패')),
    );

    expect(await storage.readEnabled(), isFalse);
  });

  test('writes the flag as the string true or false', () async {
    final secure = _FakeFlutterSecureStorage();
    final storage = SecureDeveloperModeStorage(secure);

    await storage.writeEnabled(true);
    expect(secure.values[SecureDeveloperModeStorage.enabledKey], 'true');

    await storage.writeEnabled(false);
    expect(secure.values[SecureDeveloperModeStorage.enabledKey], 'false');
  });

  test('stores the flag under the developer_mode_enabled key', () {
    expect(SecureDeveloperModeStorage.enabledKey, 'developer_mode_enabled');
  });
}
