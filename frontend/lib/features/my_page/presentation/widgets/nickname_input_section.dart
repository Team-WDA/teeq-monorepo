import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/text_field/outlined_box_text_field.dart';
import 'package:teeq/features/my_page/domain/nickname_input_rule.dart';

/// 닉네임 라벨, 입력 필드, 글자 수 카운터, 안내 문구와 오류 문구.
/// 오류 문구가 있으면(규칙 위반이나 서버 중복 응답) 입력창과 문구를 오류 색으로 그린다.
class NicknameInputSection extends StatelessWidget {
  const NicknameInputSection({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.enabled,
    required this.issue,
    required this.duplicateErrorMessage,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final NicknameInputIssue? issue;

  /// 서버가 중복을 알려 왔을 때 보여 줄 문구. 없으면 null.
  final String? duplicateErrorMessage;

  static const List<String> _guideLines = [
    '· 한글·영문·숫자 2~10자로 입력해줘.',
    '· 특수문자·공백은 사용할 수 없어.',
    '· 닉네임은 언제든지 바꿀 수 있어.',
  ];

  String? get _errorMessage => switch (issue) {
    NicknameInputIssue.invalidCharacter =>
      '한글, 영문, 숫자만 입력할 수 있어. 특수문자와 공백은 빼줘.',
    NicknameInputIssue.tooShort => '2자 이상으로 입력해줘',
    NicknameInputIssue.tooLong => '10자 이하로 입력해줘',
    null => duplicateErrorMessage,
  };

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    final hasError = errorMessage != null;
    final isCounterOverLimit = issue == NicknameInputIssue.tooLong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('닉네임', style: AppTextStyles.body16Bold),
        const SizedBox(height: AppSpacing.space8),
        OutlinedBoxTextField(
          hintText: '',
          controller: controller,
          enabled: enabled,
          hasError: hasError,
          focusedBorderColor: AppColors.accent,
          showClearButton: true,
          onChanged: onChanged,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.space8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${controller.text.length}/${NicknameInputRule.maxLength}',
            style: AppTextStyles.caption12Medium.copyWith(
              color: isCounterOverLimit
                  ? AppColors.destructiveText
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        for (final line in _guideLines)
          Text(
            line,
            style: AppTextStyles.caption12MediumMultiline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space18),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.space10),
            child: Text(
              errorMessage,
              style: AppTextStyles.caption12MediumMultiline.copyWith(
                color: AppColors.destructiveText,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
