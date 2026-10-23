import 'dart:async';

import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/auth/sign_in_result.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';

/// 호출을 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 저장소.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInResult,
    this.member,
    this.fetchMeError,
    this.logoutError,
    this.deleteAccountError,
    this.socialLoginError,
    this.socialSignUpError,
    this.changeNicknameError,
    this.replaceProfileImageError,
    this.onDeleteAccount,
  });

  final SignInResult? signInResult;
  final Member? member;

  /// 지정하면 [fetchMe]가 이 오류를 던진다.
  final Object? fetchMeError;

  /// 지정하면 [logout]이 이 오류를 던진다.
  final Object? logoutError;

  /// 지정하면 [deleteAccount]가 이 오류를 던진다.
  final Object? deleteAccountError;

  /// 지정하면 [socialLogin]이 이 오류를 던진다.
  Object? socialLoginError;

  /// 지정하면 [socialSignUp]이 이 오류를 던진다.
  final Object? socialSignUpError;

  /// 지정하면 [deleteAccount]가 호출될 때 실행한다(호출 순서 검증용).
  final void Function()? onDeleteAccount;

  /// 지정하면 [changeNickname]이 이 오류를 던진다.
  final Object? changeNicknameError;

  /// 지정하면 [replaceProfileImage]가 이 오류를 던진다.
  final Object? replaceProfileImageError;

  /// 지정하면 [changeNickname]이 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? changeNicknameGate;

  /// 지정하면 [replaceProfileImage]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? replaceProfileImageGate;

  /// 지정하면 [deleteAccount]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? deleteAccountGate;

  /// 지정하면 [logout]이 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? logoutGate;

  /// 지정하면 [fetchMe]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? fetchMeGate;

  int fetchMeCount = 0;
  int deleteAccountCount = 0;
  int logoutCount = 0;
  int socialLoginCount = 0;
  int socialSignUpCount = 0;
  int changeNicknameCount = 0;
  String? socialLoginCredential;
  ({
    String credential,
    String nickname,
    bool serviceTermsAgreed,
    bool privacyPolicyAgreed,
  })?
  socialSignUpRequest;
  String? changedNickname;
  ProfileImageFile? replacedProfileImage;

  @override
  Future<Member> fetchMe() async {
    fetchMeCount++;
    await fetchMeGate?.future;
    final error = fetchMeError;
    if (error != null) {
      throw error;
    }
    return member!;
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCount++;
    onDeleteAccount?.call();
    await deleteAccountGate?.future;
    final error = deleteAccountError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> logout() async {
    logoutCount++;
    await logoutGate?.future;
    final error = logoutError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<SignInResult> socialLogin({required String credential}) async {
    socialLoginCount++;
    socialLoginCredential = credential;
    final error = socialLoginError;
    if (error != null) {
      throw error;
    }
    return signInResult!;
  }

  @override
  Future<SignInResult> socialSignUp({
    required String credential,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    socialSignUpCount++;
    socialSignUpRequest = (
      credential: credential,
      nickname: nickname,
      serviceTermsAgreed: serviceTermsAgreed,
      privacyPolicyAgreed: privacyPolicyAgreed,
    );
    final error = socialSignUpError;
    if (error != null) {
      throw error;
    }
    return signInResult!;
  }

  @override
  Future<Member> changeNickname({required String nickname}) async {
    changeNicknameCount++;
    changedNickname = nickname;
    await changeNicknameGate?.future;
    final error = changeNicknameError;
    if (error != null) {
      throw error;
    }
    return member!.copyWith(nickname: nickname);
  }

  @override
  Future<Member> replaceProfileImage(ProfileImageFile image) async {
    replacedProfileImage = image;
    await replaceProfileImageGate?.future;
    final error = replaceProfileImageError;
    if (error != null) {
      throw error;
    }
    return member!;
  }
}
