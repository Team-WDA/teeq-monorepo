import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';
import 'package:teeq/features/auth/presentation/widgets/signup_consent_checklist.dart';

/// 소셜 로그인으로 가입을 시작한 회원의 약관 동의 화면. 동의를 받아 닉네임 단계로 넘긴다.
/// 로그아웃 경로가 없으므로 뒤로가기 버튼을 두지 않는다.
class SignupCompletionConsentScreen extends ConsumerStatefulWidget {
  const SignupCompletionConsentScreen({super.key});

  @override
  ConsumerState<SignupCompletionConsentScreen> createState() =>
      _SignupCompletionConsentScreenState();
}

class _SignupCompletionConsentScreenState
    extends ConsumerState<SignupCompletionConsentScreen> {
  bool _isNicknameStepOpen = false;
  bool _isServiceTermsAgreed = false;
  bool _isPrivacyPolicyAgreed = false;

  bool get _canProceed => _isServiceTermsAgreed && _isPrivacyPolicyAgreed;

  Future<void> _proceed() async {
    // 닉네임 화면이 열려 있는 동안 연속 탭으로 중복 이동하지 않는다.
    if (_isNicknameStepOpen) {
      return;
    }
    _isNicknameStepOpen = true;
    ref
        .read(signupDraftControllerProvider.notifier)
        .save(
          SignupDraft.empty.copyWith(
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
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitleWithDescriptionHeading(
            title: 'TeeQ를\n시작하기 전에',
            description: '서비스 이용을 위해\n약관 동의가 필요해.',
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
