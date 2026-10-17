import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/auth/data/dto/auth_response_dto.dart';
import 'package:teeq/features/auth/data/dto/member_response_dto.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';

part 'auth_repository_impl.g.dart';

/// [Dio]로 인증·회원 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<SignInResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponseDto.fromJson(response.data!).toSignInResult();
  }

  @override
  Future<SignInResult> signUp({
    required String email,
    required String password,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/members',
      data: {
        'email': email,
        'password': password,
        'nickname': nickname,
        'serviceTermsAgreed': serviceTermsAgreed,
        'privacyPolicyAgreed': privacyPolicyAgreed,
      },
    );
    return AuthResponseDto.fromJson(response.data!).toSignInResult();
  }

  @override
  Future<SignInResult> socialLogin({required String credential}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/social-login',
      data: {'socialType': 'APPLE', 'credential': credential},
    );
    return AuthResponseDto.fromJson(response.data!).toSignInResult();
  }

  @override
  Future<void> logout() async {
    await _dio.post<void>('/api/auth/logout');
  }

  @override
  Future<Member> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/members/me');
    return MemberResponseDto.fromJson(response.data!).toMember();
  }

  @override
  Future<Member> completeSignup({
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/members/me/signup-completion',
      data: {
        'nickname': nickname,
        'serviceTermsAgreed': serviceTermsAgreed,
        'privacyPolicyAgreed': privacyPolicyAgreed,
      },
    );
    return MemberResponseDto.fromJson(response.data!).toMember();
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(dioProvider));
