import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/token_storage.dart';

/// 토큰을 기기의 보안 저장소(Keychain/Keystore)에 둔다.
final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage;

  /// 저장소 읽기가 어떤 예외로든 실패하면 토큰이 없는 것으로 본다.
  /// 깨진 값이 남아 반복 실패하지 않도록 지우기를 최선으로 시도한다.
  @override
  Future<AuthTokens?> read() async {
    try {
      final accessToken = await _storage.read(key: accessTokenKey);
      final refreshToken = await _storage.read(key: refreshTokenKey);
      if (accessToken == null || refreshToken == null) {
        return null;
      }
      return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
    } on Object {
      try {
        await clear();
      } on Object {
        // 지우기 실패는 무시한다. 호출자는 토큰 없음으로 처리한다.
      }
      return null;
    }
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: refreshTokenKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }
}
