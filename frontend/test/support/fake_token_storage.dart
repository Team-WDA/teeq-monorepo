import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/token_storage.dart';

/// 메모리에 토큰을 보관하는 테스트용 저장소.
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage({this.storedTokens, this.clearError});

  /// 현재 저장된 토큰. 비어 있으면 null.
  AuthTokens? storedTokens;

  /// 지정하면 [clear]가 이 오류를 던진다.
  final Object? clearError;

  int readCount = 0;
  AuthTokens? savedTokens;
  int clearCount = 0;

  @override
  Future<AuthTokens?> read() async {
    readCount++;
    return storedTokens;
  }

  @override
  Future<void> save(AuthTokens tokens) async {
    savedTokens = tokens;
    storedTokens = tokens;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    final error = clearError;
    if (error != null) {
      throw error;
    }
    storedTokens = null;
  }
}
