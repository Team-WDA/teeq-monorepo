import 'package:dio/dio.dart';
import 'package:teeq/core/auth/auth_tokens.dart';

/// 리프레시 토큰으로 새 토큰 한 쌍을 받아 온다.
abstract interface class TokenRefresher {
  Future<AuthTokens> refresh(String refreshToken);
}

/// `POST /api/auth/refresh`를 호출하는 구현.
/// `AuthInterceptor`를 다시 타지 않도록 인증 인터셉터가 없는 Dio를 받는다.
final class DioTokenRefresher implements TokenRefresher {
  DioTokenRefresher(this._plainDio);

  final Dio _plainDio;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _plainDio.post<Map<String, dynamic>>(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final body = response.data;
    if (body == null) {
      throw StateError('토큰 갱신 응답 본문이 비어 있다');
    }
    return AuthTokens(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );
  }
}
