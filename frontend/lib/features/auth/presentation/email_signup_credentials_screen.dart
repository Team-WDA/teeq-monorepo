import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/text_field/underline_labeled_text_field.dart';
import 'package:teeq/features/auth/domain/auth_input_validator.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';
import 'package:teeq/features/auth/presentation/widgets/signup_consent_checklist.dart';

/// 이메일 가입 1단계. 이메일·비밀번호·약관 동의를 받아 닉네임 단계로 넘긴다.
class EmailSignupCredentialsScreen extends ConsumerStatefulWidget {
  const EmailSignupCredentialsScreen({super.key});

  @override
  ConsumerState<EmailSignupCredentialsScreen> createState() =>
      _EmailSignupCredentialsScreenState();
}

class _EmailSignupCredentialsScreenState
    extends ConsumerState<EmailSignupCredentialsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isNicknameStepOpen = false;
  bool _isServiceTermsAgreed = false;
  bool _isPrivacyPolicyAgreed = false;

  bool get _canProceed =>
      AuthInputValidator.isEmailFormatValid(_emailController.text.trim()) &&
      AuthInputValidator.isPasswordValid(_passwordController.text) &&
      _isServiceTermsAgreed &&
      _isPrivacyPolicyAgreed;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    // 닉네임 화면이 열려 있는 동안 연속 탭으로 중복 이동하지 않는다.
    if (_isNicknameStepOpen) {
      return;
    }
    _isNicknameStepOpen = true;
    ref
        .read(signupDraftControllerProvider.notifier)
        .save(
          SignupDraft(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            isServiceTermsAgreed: _isServiceTermsAgreed,
            isPrivacyPolicyAgreed: _isPrivacyPolicyAgreed,
          ),
        );
    await context.push(AppRoutes.signupNickname);
    _isNicknameStepOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    // 이 화면이 스택에 있는 동안 가입 입력값 provider를 유지한다.
    ref.watch(signupDraftControllerProvider);
    return BottomActionScreenLayout(
      onBackPressed: context.pop,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitleWithDescriptionHeading(
            title: 'TeeQ를\n시작해볼까?',
            description: '이메일과 비밀번호만으로\n간편하게 시작할 수 있어.',
          ),
          const SizedBox(height: AppSpacing.space40),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnderlineLabeledTextField(
                  label: '이메일',
                  hintText: '이메일을 입력해주세요.',
                  controller: _emailController,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.space24),
                UnderlineLabeledTextField(
                  label: '비밀번호',
                  hintText: '비밀번호를 입력해주세요.',
                  controller: _passwordController,
                  onChanged: (_) => setState(() {}),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space40),
          SignupConsentChecklist(
            isServiceTermsAgreed: _isServiceTermsAgreed,
            isPrivacyPolicyAgreed: _isPrivacyPolicyAgreed,
            onServiceTermsChanged: (isAgreed) =>
                setState(() => _isServiceTermsAgreed = isAgreed),
            onPrivacyPolicyChanged: (isAgreed) =>
                setState(() => _isPrivacyPolicyAgreed = isAgreed),
          ),
        ],
      ),
      bottomAction: PrimaryFilledButton(
        label: '다음',
        onPressed: _canProceed ? _proceed : null,
      ),
    );
  }
}
