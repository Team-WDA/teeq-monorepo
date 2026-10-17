import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/secure_token_storage.dart';

part 'token_storage.g.dart';

/// 토큰 영속 저장소 계약. 테스트에서는 메모리 구현으로 바꾼다.
abstract interface class TokenStorage {
  /// 저장된 토큰을 돌려준다. 없거나 읽을 수 없으면 null.
  Future<AuthTokens?> read();

  Future<void> save(AuthTokens tokens);

  Future<void> clear();
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) =>
    SecureTokenStorage(const FlutterSecureStorage());
