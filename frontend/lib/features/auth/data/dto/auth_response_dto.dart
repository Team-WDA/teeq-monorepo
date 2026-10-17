import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/core/auth/auth_tokens.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/features/auth/data/dto/login_type_json.dart';

part 'auth_response_dto.g.dart';

/// 로그인·가입·소셜 로그인 응답(`AuthResponse`).
@JsonSerializable(createToJson: false)
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.memberId,
    required this.nickname,
    required this.hasAiCharacter,
    required this.loginType,
    required this.profileImageUrl,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  final String accessToken;
  final String refreshToken;
  final String memberId;
  final String? nickname;
  final bool hasAiCharacter;
  @JsonKey(fromJson: loginTypeFromJson)
  final LoginType loginType;
  final String? profileImageUrl;

  SignInResult toSignInResult() => SignInResult(
    tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
    member: Member(
      memberId: memberId,
      nickname: nickname,
      hasAiCharacter: hasAiCharacter,
      loginType: loginType,
      profileImageUrl: profileImageUrl,
    ),
  );
}
