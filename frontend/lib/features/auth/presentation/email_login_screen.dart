import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/text_field/underline_labeled_text_field.dart';
import 'package:teeq/features/auth/domain/auth_input_validator.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';

/// 이메일과 비밀번호로 로그인하는 화면. 성공 후 이동은 authRedirect가 맡는다.
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRequestInProgress = false;

  bool get _canSubmit =>
      AuthInputValidator.isEmailFormatValid(_emailController.text.trim()) &&
      _passwordController.text.isNotEmpty &&
      !_isRequestInProgress;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    try {
      await authFlow.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      TextInput.finishAutofillContext();
    } on Object catch (error) {
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
            title: '다시\n만나서 반가워!',
            description: '로그인하고\n다시 대화를 이어가자.',
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
                  autofillHints: const [AutofillHints.password],
                ),
              ],
            ),
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
