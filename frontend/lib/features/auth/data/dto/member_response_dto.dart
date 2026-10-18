import 'package:json_annotation/json_annotation.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/features/auth/data/dto/login_type_json.dart';

part 'member_response_dto.g.dart';

/// 회원 조회·가입 완료 응답(`MemberResponse`). 앱이 쓰지 않는 `email`은 받지 않는다.
@JsonSerializable(createToJson: false)
class MemberResponseDto {
  const MemberResponseDto({
    required this.memberId,
    required this.nickname,
    required this.hasAiCharacter,
    required this.loginType,
    required this.profileImageUrl,
  });

  factory MemberResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MemberResponseDtoFromJson(json);

  final String memberId;
  final String? nickname;
  final bool hasAiCharacter;
  @JsonKey(fromJson: loginTypeFromJson)
  final LoginType loginType;
  final String? profileImageUrl;

  Member toMember() => Member(
    memberId: memberId,
    nickname: nickname,
    hasAiCharacter: hasAiCharacter,
    loginType: loginType,
    profileImageUrl: profileImageUrl,
  );
}
