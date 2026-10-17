import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/core/auth/login_type.dart';

part 'member.freezed.dart';

/// 로그인한 회원의 앱 내 표현.
@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required String memberId,
    String? nickname,
    required bool hasAiCharacter,
    required LoginType loginType,
    String? profileImageUrl,
  }) = _Member;

  /// 닉네임이 있어야 가입이 끝난 회원이다. Apple 첫 로그인은 닉네임 없이 시작한다.
  bool get isSignupCompleted => nickname != null;
}
