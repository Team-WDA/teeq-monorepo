import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/core/auth/token_storage.dart';

part 'auth_session.g.dart';

@Riverpod(keepAlive: true)
AuthSession authSession(Ref ref) => AuthSession(ref);

/// 로그인 세션(토큰 저장소, 회원, 로그인 상태)을 한 번에 바꾸는 곳.
class AuthSession {
  AuthSession(this._ref);

  final Ref _ref;

  /// 로그인 성공: 토큰 저장 → 회원 보관 → 상태 전환 순서.
  Future<void> signIn(SignInResult result) async {
    await _ref.read(tokenStorageProvider).save(result.tokens);
    _ref.read(currentMemberControllerProvider.notifier).update(result.member);
    _ref.read(authStatusControllerProvider.notifier).markSignedIn();
  }

  /// 저장된 토큰으로 회원을 복원했다. 토큰은 이미 저장돼 있다.
  Future<void> restored(Member member) async {
    _ref.read(currentMemberControllerProvider.notifier).update(member);
    _ref.read(authStatusControllerProvider.notifier).markSignedIn();
  }

  /// 상태 → 회원 → 저장소 순서로 지운다. 라우터가 상태와 회원을 함께 들으므로
  /// signedIn인 채 회원만 비워지는 순간이 없어야 하고, 저장소 삭제가 실패해도
  /// 상태는 이미 signedOut이다.
  Future<void> signOut() async {
    _ref.read(authStatusControllerProvider.notifier).markSignedOut();
    _ref.read(currentMemberControllerProvider.notifier).clear();
    await _ref.read(tokenStorageProvider).clear();
  }
}
