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
    this.completeSignupError,
    this.changeNicknameError,
    this.changePasswordError,
    this.replaceProfileImageError,
  });

  final SignInResult? signInResult;
  final Member? member;

  /// 지정하면 [fetchMe]가 이 오류를 던진다.
  final Object? fetchMeError;

  /// 지정하면 [logout]이 이 오류를 던진다.
  final Object? logoutError;

  /// 지정하면 [deleteAccount]가 이 오류를 던진다.
  final Object? deleteAccountError;

  /// 지정하면 [completeSignup]이 이 오류를 던진다.
  final Object? completeSignupError;

  /// 지정하면 [changeNickname]이 이 오류를 던진다.
  final Object? changeNicknameError;

  /// 지정하면 [changePassword]가 이 오류를 던진다.
  final Object? changePasswordError;

  /// 지정하면 [replaceProfileImage]가 이 오류를 던진다.
  final Object? replaceProfileImageError;

  /// 지정하면 [changeNickname]이 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? changeNicknameGate;

  /// 지정하면 [replaceProfileImage]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? replaceProfileImageGate;

  /// 지정하면 [changePassword]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? changePasswordGate;

  /// 지정하면 [deleteAccount]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? deleteAccountGate;

  /// 지정하면 [logout]이 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? logoutGate;

  /// 지정하면 [fetchMe]가 이 게이트가 완료될 때까지 응답을 미룬다.
  Completer<void>? fetchMeGate;

  int fetchMeCount = 0;
  int deleteAccountCount = 0;
  int logoutCount = 0;
  int completeSignupCount = 0;
  int changeNicknameCount = 0;
  int changePasswordCount = 0;
  String? socialLoginCredential;
  ({String nickname, bool serviceTermsAgreed, bool privacyPolicyAgreed})?
  completedSignup;
  String? changedNickname;
  ({String currentPassword, String newPassword})? changedPassword;
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
  }) async {
    completeSignupCount++;
    completedSignup = (
      nickname: nickname,
      serviceTermsAgreed: serviceTermsAgreed,
      privacyPolicyAgreed: privacyPolicyAgreed,
    );
    final error = completeSignupError;
    if (error != null) {
      throw error;
    }
    return member!;
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
  Future<SignInResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCount++;
    changedPassword = (
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await changePasswordGate?.future;
    final error = changePasswordError;
    if (error != null) {
      throw error;
    }
    return signInResult!;
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
