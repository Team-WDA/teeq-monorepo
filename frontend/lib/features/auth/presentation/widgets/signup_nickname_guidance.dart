import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/auth/domain/nickname_input_rule.dart';

/// 가입 닉네임 입력창 아래의 안내 문구와, 규칙 위반 시 그 아래 오류 문구.
class SignupNicknameGuidance extends StatelessWidget {
  const SignupNicknameGuidance({super.key, required this.issue});

  final NicknameInputIssue? issue;

  static const String _guidanceMessage = '한글만 2~10자 · 공백 없이 입력해줘';

  String? get _errorMessage => switch (issue) {
    NicknameInputIssue.invalidCharacter => '한글만 입력할 수 있어. 영문,숫자,특수문자는 빼줘.',
    NicknameInputIssue.whitespace => '공백 없이 입력해줘',
    NicknameInputIssue.tooShort => '2자 이상으로 입력해줘',
    NicknameInputIssue.tooLong => '10자 이하로 입력해줘',
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _guidanceMessage,
          style: AppTextStyles.caption12Medium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space8),
          Text(
            errorMessage,
            style: AppTextStyles.caption12Medium.copyWith(
              color: AppColors.destructiveText,
            ),
          ),
        ],
      ],
    );
  }
}
