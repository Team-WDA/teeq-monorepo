import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/secure_token_storage.dart';

/// 메모리 맵으로 동작하고, 지정하면 읽기에서 예외를 던지는 가짜 보안 저장소.
class FakeFlutterSecureStorage extends FlutterSecureStorage {
  FakeFlutterSecureStorage({this.readError});

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

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  const tokens = AuthTokens(accessToken: 'access', refreshToken: 'refresh');

  test('save_thenRead_roundTrips', () async {
    final storage = SecureTokenStorage(FakeFlutterSecureStorage());

    await storage.save(tokens);

    expect(await storage.read(), tokens);
  });

  test('read_whenEmpty_returnsNull', () async {
    final storage = SecureTokenStorage(FakeFlutterSecureStorage());

    expect(await storage.read(), isNull);
  });

  test('read_whenOnlyOneValueStored_returnsNull', () async {
    final fake = FakeFlutterSecureStorage();
    fake.values[SecureTokenStorage.accessTokenKey] = 'access';

    expect(await SecureTokenStorage(fake).read(), isNull);
  });

  test('read_whenStorageThrows_returnsNullAndClears', () async {
    final fake = FakeFlutterSecureStorage(
      readError: PlatformException(code: 'keystore'),
    );
    fake.values[SecureTokenStorage.accessTokenKey] = 'access';
    fake.values[SecureTokenStorage.refreshTokenKey] = 'refresh';
    final storage = SecureTokenStorage(fake);

    expect(await storage.read(), isNull);
    expect(fake.values, isEmpty);
  });

  test('clear_removesBothTokens', () async {
    final fake = FakeFlutterSecureStorage();
    final storage = SecureTokenStorage(fake);
    await storage.save(tokens);

    await storage.clear();

    expect(fake.values, isEmpty);
  });
}
