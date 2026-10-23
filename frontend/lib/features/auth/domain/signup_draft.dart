import 'package:freezed_annotation/freezed_annotation.dart';

part 'signup_draft.freezed.dart';

/// 가입 마지막 단계(닉네임)에서 계정을 어떻게 준비하는지 정한다.
enum SignupMode {
  /// 이미 Firebase에 로그인된 계정(Apple, Google, 가입이 필요한 이메일 로그인)으로 가입한다.
  /// ID token은 현재 Firebase 세션에서 받고, 계정 생성도 비밀번호도 쓰지 않는다.
  firebaseSession,

  /// 입력한 이메일·비밀번호로 Firebase 계정을 만들며 가입한다.
  emailSignup,
}

/// 가입 앞 단계(약관, 이메일 가입이면 이메일·비밀번호)에서 닉네임 단계로 넘기는 임시 입력값.
@freezed
abstract class SignupDraft with _$SignupDraft {
  const SignupDraft._();

  const factory SignupDraft({
    required SignupMode mode,
    required String email,
    required String password,
    required bool isServiceTermsAgreed,
    required bool isPrivacyPolicyAgreed,
  }) = _SignupDraft;

  static const SignupDraft empty = SignupDraft(
    mode: SignupMode.firebaseSession,
    email: '',
    password: '',
    isServiceTermsAgreed: false,
    isPrivacyPolicyAgreed: false,
  );

  /// 필수 약관 두 가지에 모두 동의했는지.
  bool get isAllRequiredConsentAgreed =>
      isServiceTermsAgreed && isPrivacyPolicyAgreed;

  /// 비밀번호만 비운 사본. 가입을 마친 뒤 메모리에 남기지 않으려고 쓴다.
  SignupDraft withoutPassword() => copyWith(password: '');
}
