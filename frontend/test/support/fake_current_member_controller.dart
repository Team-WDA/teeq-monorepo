import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/member.dart';

/// 테스트에서 처음 보관할 회원을 정하는 가짜 컨트롤러.
class FakeCurrentMemberController extends CurrentMemberController {
  FakeCurrentMemberController(this._initialMember);

  final Member? _initialMember;

  @override
  Member? build() => _initialMember;
}
