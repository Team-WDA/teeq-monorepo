import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/auth/data/dto/auth_response_dto.dart';
import 'package:teeq/features/auth/data/dto/member_response_dto.dart';
import 'package:teeq/features/auth/data/dto/nickname_availability_response_dto.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';

part 'auth_repository_impl.g.dart';

/// [Dio]로 인증·회원 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<SignInResult> login({required String credential}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'credential': credential},
    );
    return AuthResponseDto.fromJson(response.data!).toSignInResult();
  }

  @override
  Future<SignInResult> signUp({
    required String credential,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/signup',
      data: {
        'credential': credential,
        'nickname': nickname,
        'serviceTermsAgreed': serviceTermsAgreed,
        'privacyPolicyAgreed': privacyPolicyAgreed,
      },
    );
    return AuthResponseDto.fromJson(response.data!).toSignInResult();
  }

  @override
  Future<bool> checkNicknameAvailability({required String nickname}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/members/nickname-availability',
      queryParameters: {'nickname': nickname},
    );
    return NicknameAvailabilityResponseDto.fromJson(response.data!).available;
  }

  @override
  Future<void> logout() async {
    await _dio.post<void>('/api/auth/logout');
  }

  @override
  Future<void> deleteAccount() async {
    await _dio.delete<void>('/api/members/me');
  }

  @override
  Future<Member> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/members/me');
    return MemberResponseDto.fromJson(response.data!).toMember();
  }

  @override
  Future<Member> changeNickname({required String nickname}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/members/me/nickname',
      data: {'nickname': nickname},
    );
    return MemberResponseDto.fromJson(response.data!).toMember();
  }

  @override
  Future<Member> replaceProfileImage(ProfileImageFile image) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        image.bytes,
        filename: image.fileName,
        contentType: _contentTypeOf(image.fileName),
      ),
    });
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/members/me/profile-image',
      data: formData,
    );
    return MemberResponseDto.fromJson(response.data!).toMember();
  }

  /// 확장자로 업로드 형식을 정한다. 서버는 내용으로 형식을 다시 판별한다.
  DioMediaType _contentTypeOf(String fileName) {
    final lowerCaseName = fileName.toLowerCase();
    if (lowerCaseName.endsWith('.png')) {
      return DioMediaType('image', 'png');
    }
    return DioMediaType('image', 'jpeg');
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(dioProvider));
