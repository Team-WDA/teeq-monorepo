import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 피드백 문항 하나. 제목 뒤에 작은 보조 안내([hint], 예: "(단일 선택)")를 붙이거나,
/// 제목 아래 별도 줄에 도움말([helperText], 예: "선택")을 둘 수 있다.
class RequiredFeedbackQuestion extends StatelessWidget {
  const RequiredFeedbackQuestion({
    super.key,
    required this.title,
    this.hint,
    this.helperText,
    required this.child,
  });

  final String title;
  final String? hint;
  final String? helperText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hintText = hint;
    final helper = helperText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // 도움말이 있으면 제목·도움말·컨트롤을 다른 상세 문항처럼 촘촘하게 붙인다.
      spacing: helper == null ? AppSpacing.space16 : AppSpacing.space8,
      children: [
        Text.rich(
          TextSpan(
            text: title,
            style: AppTextStyles.body16BoldMultiline,
            children: [
              if (hintText != null)
                TextSpan(
                  text: ' $hintText',
                  style: AppTextStyles.caption12SemiBold.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (helper != null)
          Text(
            helper,
            style: AppTextStyles.caption12RegularMultiline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        child,
      ],
    );
  }
}
