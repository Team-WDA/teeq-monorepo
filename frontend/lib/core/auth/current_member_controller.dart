import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/member.dart';

part 'current_member_controller.g.dart';

/// 로그인한 회원 보관소. 로그아웃 상태에서는 null이다.
@Riverpod(keepAlive: true)
class CurrentMemberController extends _$CurrentMemberController {
  @override
  Member? build() => null;

  void update(Member member) {
    state = member;
  }

  void clear() {
    state = null;
  }
}
