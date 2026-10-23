import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/core/auth/login_type.dart';

part 'member.freezed.dart';

/// 로그인한 회원의 앱 내 표현.
@freezed
abstract class Member with _$Member {
  const factory Member({
    required String memberId,
    String? email,
    required String nickname,
    required bool hasAiCharacter,
    required LoginType loginType,
    String? profileImageUrl,
  }) = _Member;
}
