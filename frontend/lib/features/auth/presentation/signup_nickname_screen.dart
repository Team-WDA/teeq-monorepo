import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/core/ui/text_field/outlined_box_text_field.dart';
import 'package:teeq/features/auth/domain/auth_input_validator.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/auth/presentation/signup_draft_controller.dart';

/// 소셜 가입 마지막 단계. 닉네임을 받아 가입을 마치고 온보딩으로 이동한다.
class SignupNicknameScreen extends ConsumerStatefulWidget {
  const SignupNicknameScreen({super.key});

  @override
  ConsumerState<SignupNicknameScreen> createState() =>
      _SignupNicknameScreenState();
}

class _SignupNicknameScreenState extends ConsumerState<SignupNicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isRequestInProgress = false;

  bool get _canSubmit =>
      AuthInputValidator.isNicknameValid(_nicknameController.text.trim()) &&
      !_isRequestInProgress;

  @override
  void initState() {
    super.initState();
    // 약관 동의 없이 이 화면에 들어오면 약관 화면으로 되돌린다.
    if (!ref.read(signupDraftControllerProvider).isAllRequiredConsentAgreed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.signupCompletion);
        }
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isRequestInProgress) {
      return;
    }
    setState(() => _isRequestInProgress = true);
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    final draft = ref.read(signupDraftControllerProvider);
    final nickname = _nicknameController.text.trim();
    try {
      await authFlow.completeSocialSignup(
        nickname: nickname,
        serviceTermsAgreed: draft.isServiceTermsAgreed,
        privacyPolicyAgreed: draft.isPrivacyPolicyAgreed,
      );
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.onboarding);
    } on Object catch (error) {
      // 중복 닉네임 등 오류는 알리고 이 화면에 머문다.
      errorHandler.handle(error);
    } finally {
      if (mounted) {
        setState(() => _isRequestInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomActionScreenLayout(
      onBackPressed: context.pop,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitleWithDescriptionHeading(
            title: '우리,\n어떻게 부를까?',
            description: '입력한 닉네임으로 너만의 티크가\n앞으로 너를 불러줄 거야.',
          ),
          const SizedBox(height: AppSpacing.space40),
          OutlinedBoxTextField(
            hintText: '너를 뭐라고 불러줄까?',
            controller: _nicknameController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.space12),
          const Center(
            child: AccentOutlineHintTag(message: '닉네임은 나중에 언제든지 변경 가능해.'),
          ),
        ],
      ),
      bottomAction: PrimaryFilledButton(
        label: '다음',
        onPressed: _canSubmit ? _submit : null,
      ),
    );
  }
}
