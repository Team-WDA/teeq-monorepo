import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/features/auth/data/dto/auth_response_dto.dart';
import 'package:teeq/features/auth/data/dto/member_response_dto.dart';

Map<String, dynamic> _authJson({Object? nickname = '티큐', String? loginType}) =>
    {
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'memberId': 'member-1',
      'nickname': nickname,
      'hasAiCharacter': true,
      'loginType': loginType ?? 'EMAIL',
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
    expect(result.member.loginType, LoginType.email);
    expect(result.member.profileImageUrl, '/media/a.jpg');
    expect(result.member.isSignupCompleted, isTrue);
  });

  test('authResponse_nullNickname_mapsToIncompleteMember', () {
    final result = AuthResponseDto.fromJson(
      _authJson(nickname: null, loginType: 'APPLE'),
    ).toSignInResult();

    expect(result.member.nickname, isNull);
    expect(result.member.loginType, LoginType.apple);
    expect(result.member.isSignupCompleted, isFalse);
  });

  test('memberResponse_mapsEmailToMember', () {
    final member = MemberResponseDto.fromJson({
      'memberId': 'member-1',
      'email': 'user@example.com',
      'nickname': '티큐',
      'hasAiCharacter': false,
      'loginType': 'EMAIL',
      'profileImageUrl': null,
    }).toMember();

    expect(member.memberId, 'member-1');
    expect(member.email, 'user@example.com');
    expect(member.nickname, '티큐');
    expect(member.hasAiCharacter, isFalse);
    expect(member.loginType, LoginType.email);
    expect(member.profileImageUrl, isNull);
  });

  test('memberResponse_parsesWhenEmailIsNull', () {
    final member = MemberResponseDto.fromJson({
      'memberId': 'member-1',
      'email': null,
      'nickname': '티큐',
      'hasAiCharacter': false,
      'loginType': 'EMAIL',
      'profileImageUrl': null,
    }).toMember();

    expect(member.email, isNull);
  });

  test('unknownLoginType_throws', () {
    expect(
      () => AuthResponseDto.fromJson(_authJson(loginType: 'GOOGLE')),
      throwsA(anything),
    );
    expect(
      () => MemberResponseDto.fromJson({
        'memberId': 'member-1',
        'hasAiCharacter': false,
        'loginType': 'GOOGLE',
      }),
      throwsA(anything),
    );
  });
}
