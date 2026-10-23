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
    this.loginError,
    this.signUpError,
    this.isNicknameAvailable = true,
    this.nicknameAvailabilityError,
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

  /// 지정하면 [login]이 이 오류를 던진다.
  Object? loginError;

  /// 지정하면 [signUp]이 이 오류를 던진다.
  final Object? signUpError;

  /// [checkNicknameAvailability]가 돌려줄 값.
  final bool isNicknameAvailable;

  /// 지정하면 [checkNicknameAvailability]가 이 오류를 던진다.
  final Object? nicknameAvailabilityError;

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
  int loginCount = 0;
  int signUpCount = 0;
  int nicknameAvailabilityCount = 0;
  String? checkedNickname;
  int changeNicknameCount = 0;
  String? loginCredential;
  ({
    String credential,
    String nickname,
    bool serviceTermsAgreed,
    bool privacyPolicyAgreed,
  })?
  signUpRequest;
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
  Future<bool> checkNicknameAvailability({required String nickname}) async {
    nicknameAvailabilityCount++;
    checkedNickname = nickname;
    final error = nicknameAvailabilityError;
    if (error != null) {
      throw error;
    }
    return isNicknameAvailable;
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
  Future<SignInResult> login({required String credential}) async {
    loginCount++;
    loginCredential = credential;
    final error = loginError;
    if (error != null) {
      throw error;
    }
    return signInResult!;
  }

  @override
  Future<SignInResult> signUp({
    required String credential,
    required String nickname,
    required bool serviceTermsAgreed,
    required bool privacyPolicyAgreed,
  }) async {
    signUpCount++;
    signUpRequest = (
      credential: credential,
      nickname: nickname,
      serviceTermsAgreed: serviceTermsAgreed,
      privacyPolicyAgreed: privacyPolicyAgreed,
    );
    final error = signUpError;
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
