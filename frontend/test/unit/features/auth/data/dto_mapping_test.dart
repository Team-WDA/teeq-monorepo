import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/features/auth/data/dto/auth_response_dto.dart';
import 'package:teeq/features/auth/data/dto/member_response_dto.dart';

Map<String, dynamic> _authJson({String? loginType}) => {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'memberId': 'member-1',
  'nickname': '티큐',
  'hasAiCharacter': true,
  'loginType': loginType ?? 'GOOGLE',
  'profileImageUrl': '/media/a.jpg',
};

void main() {
  test('authResponse_withNickname_mapsMemberAndTokens', () {
    final result = AuthResponseDto.fromJson(_authJson()).toSignInResult();

    expect(result.tokens.accessToken, 'access');
    expect(result.tokens.refreshToken, 'refresh');
    expect(result.member.memberId, 'member-1');
    expect(result.member.nickname, '티큐');
    expect(result.member.hasAiCharacter, isTrue);
    expect(result.member.loginType, LoginType.google);
    expect(result.member.profileImageUrl, '/media/a.jpg');
  });

  test('authResponse_apple_mapsAppleLoginType', () {
    final result = AuthResponseDto.fromJson(_authJson(loginType: 'APPLE'))
        .toSignInResult();

    expect(result.member.loginType, LoginType.apple);
  });

  test('memberResponse_mapsEmailToMember', () {
    final member = MemberResponseDto.fromJson({
      'memberId': 'member-1',
      'email': 'user@example.com',
      'nickname': '티큐',
      'hasAiCharacter': false,
      'loginType': 'GOOGLE',
      'profileImageUrl': null,
    }).toMember();

    expect(member.memberId, 'member-1');
    expect(member.email, 'user@example.com');
    expect(member.nickname, '티큐');
    expect(member.hasAiCharacter, isFalse);
    expect(member.loginType, LoginType.google);
    expect(member.profileImageUrl, isNull);
  });

  test('memberResponse_parsesWhenEmailIsNull', () {
    final member = MemberResponseDto.fromJson({
      'memberId': 'member-1',
      'email': null,
      'nickname': '티큐',
      'hasAiCharacter': false,
      'loginType': 'GOOGLE',
      'profileImageUrl': null,
    }).toMember();

    expect(member.email, isNull);
  });

  test('emailLoginType_mapsToEmail', () {
    final result = AuthResponseDto.fromJson(_authJson(loginType: 'EMAIL'))
        .toSignInResult();

    expect(result.member.loginType, LoginType.email);
  });

  test('unknownLoginType_throws', () {
    expect(
      () => AuthResponseDto.fromJson(_authJson(loginType: 'KAKAO')),
      throwsA(anything),
    );
    expect(
      () => MemberResponseDto.fromJson({
        'memberId': 'member-1',
        'nickname': '티큐',
        'hasAiCharacter': false,
        'loginType': 'KAKAO',
      }),
      throwsA(anything),
    );
  });
}
