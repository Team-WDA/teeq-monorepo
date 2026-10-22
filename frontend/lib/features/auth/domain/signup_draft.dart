import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_draft.freezed.dart';

/// 이메일 가입 1단계(자격 증명)에서 2단계(닉네임)로 넘기는 임시 입력값.
@freezed
abstract class SignupDraft with _$SignupDraft {
  const SignupDraft._();

  const factory SignupDraft({
    required String email,
    required String password,
    required bool isServiceTermsAgreed,
    required bool isPrivacyPolicyAgreed,
  }) = _SignupDraft;

  static const SignupDraft empty = SignupDraft(
    email: '',
    password: '',
    isServiceTermsAgreed: false,
    isPrivacyPolicyAgreed: false,
  );

  /// 필수 약관 두 가지에 모두 동의했는지.
  bool get isAllRequiredConsentAgreed =>
      isServiceTermsAgreed && isPrivacyPolicyAgreed;
}
