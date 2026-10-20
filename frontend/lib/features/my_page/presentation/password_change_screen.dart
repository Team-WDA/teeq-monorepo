import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/text_field/underline_labeled_text_field.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/my_page/domain/password_change_input_rule.dart';

/// 마이 화면의 비밀번호 변경 행에서 들어오는 비밀번호 변경 폼 화면.
class PasswordChangeScreen extends ConsumerStatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  ConsumerState<PasswordChangeScreen> createState() =>
      _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends ConsumerState<PasswordChangeScreen> {
  /// 시안의 현재 비밀번호 불일치 문구. 서버 errorMessage는 쓰지 않는다.
  static const String _currentPasswordMismatchMessage = '현재 비밀번호가 일치하지 않아';
  static const String _confirmationMismatchMessage = '새 비밀번호가 일치하지 않아';

  /// 새 비밀번호를 아직 입력하지 않았을 때 필드 아래에 보이는 안내. 오류가 생기면 오류 문구로 바뀐다.
  static const String _newPasswordGuideMessage = '8자 이상, 영문과 숫자를 함께 입력해줘';

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmationController = TextEditingController();
  bool _isRequestInProgress = false;
  bool _isCurrentPasswordMismatch = false;

  bool get _canSubmit =>
      !_isRequestInProgress &&
      !_isCurrentPasswordMismatch &&
      PasswordChangeInputRule.canSubmit(
        current: _currentPasswordController.text,
        next: _newPasswordController.text,
        confirmation: _confirmationController.text,
      );

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmationController.dispose();
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
      await authFlow.changePassword(
        current: _currentPasswordController.text,
        next: _newPasswordController.text,
      );
      if (!mounted) {
        return;
      }
      // 폼으로 되돌아오지 못하게 완료 화면으로 교체한다. 이동이 끝날 때까지 잠금을 유지한다.
      context.pushReplacement(AppRoutes.passwordChangeCompletion);
    } on Object catch (error) {
      final isCurrentPasswordMismatch =
          error is ApiException &&
          error.errorCode == ErrorCode.invalidCurrentPassword;
      if (isCurrentPasswordMismatch) {
        if (mounted) {
          setState(() {
            _isCurrentPasswordMismatch = true;
            _isRequestInProgress = false;
          });
        }
        return;
      }
      errorHandler.handle(error);
      if (mounted) {
        setState(() => _isRequestInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final newPasswordIssue = PasswordChangeInputRule.newPasswordIssueOf(
      _newPasswordController.text,
    );
    final isConfirmationMismatch =
        PasswordChangeInputRule.isConfirmationMismatch(
          _newPasswordController.text,
          _confirmationController.text,
        );
    return BottomActionScreenLayout(
      onBackPressed: context.pop,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenTitleWithDescriptionHeading(
            title: '비밀번호 변경',
            description: '안전한 계정 사용을 위해\n새로운 비밀번호를 설정해줘.',
            titleStyle: AppTextStyles.title28Bold,
            titleDescriptionGap: AppSpacing.space28,
          ),
          const SizedBox(height: AppSpacing.space20),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnderlineLabeledTextField(
                  label: '현재 비밀번호',
                  hintText: '현재 비밀번호를 입력해줘.',
                  controller: _currentPasswordController,
                  onChanged: (_) => setState(() {
                    // 입력이 바뀌면 이전 불일치 응답은 더 이상 유효하지 않다.
                    _isCurrentPasswordMismatch = false;
                  }),
                  enabled: !_isRequestInProgress,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  errorMessage: _isCurrentPasswordMismatch
                      ? _currentPasswordMismatchMessage
                      : null,
                ),
                const SizedBox(height: AppSpacing.space24),
                UnderlineLabeledTextField(
                  label: '새 비밀번호',
                  hintText: '새 비밀번호를 입력해줘.',
                  controller: _newPasswordController,
                  onChanged: (_) => setState(() {}),
                  enabled: !_isRequestInProgress,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  errorMessage: newPasswordIssue?.message,
                ),
                if (_newPasswordController.text.isEmpty) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    _newPasswordGuideMessage,
                    style: AppTextStyles.caption12MediumMultiline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space24),
                UnderlineLabeledTextField(
                  label: '새 비밀번호 확인',
                  hintText: '새 비밀번호를 한 번 더 입력해줘.',
                  controller: _confirmationController,
                  onChanged: (_) => setState(() {}),
                  enabled: !_isRequestInProgress,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  errorMessage: isConfirmationMismatch
                      ? _confirmationMismatchMessage
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
        ],
      ),
      bottomAction: PrimaryFilledButton(
        label: '비밀번호 변경',
        onPressed: _canSubmit ? _submit : null,
      ),
    );
  }
}
