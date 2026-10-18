import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';

/// 호출을 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 저장소.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInResult,
    this.member,
    this.fetchMeError,
    this.logoutError,
  });

  final SignInResult? signInResult;
  final Member? member;

  /// 지정하면 [fetchMe]가 이 오류를 던진다.
  final Object? fetchMeError;

  /// 지정하면 [logout]이 이 오류를 던진다.
  final Object? logoutError;

  int fetchMeCount = 0;
  int logoutCount = 0;
  String? socialLoginCredential;

  @override
  Future<Member> fetchMe() async {
    fetchMeCount++;
    final error = fetchMeError;
    if (error != null) {
      throw error;
    }
    return member!;
  }

  @override
  Future<void> logout() async {
    logoutCount++;
    final error = logoutError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<SignInResult> socialLogin({required String credential}) async {
    socialLoginCredential = credential;
    return signInResult!;
  }

  @override
  Future<SignInResult> login({
    required String email,
    required String password,
  }) async => signInResult!;

  @override
  Future<SignInResult> signUp({
    required String email,
    required String password,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async => signInResult!;

  @override
  Future<Member> completeSignup({
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async => member!;
}
