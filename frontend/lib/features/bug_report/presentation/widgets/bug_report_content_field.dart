import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/bug_report/domain/bug_report_input_limits.dart';
import 'package:teeq/features/bug_report/presentation/widgets/utf16_length_limiting_formatter.dart';

/// 제보 내용을 적는 여러 줄 입력 상자. 오른쪽 아래에 `n/2000`을 보여 준다.
/// 입력 값은 [controller]가 보관하므로 화면이 읽는다.
class BugReportContentField extends StatelessWidget {
  const BugReportContentField({
    super.key,
    required this.controller,
    this.isEnabled = true,
  });

  final TextEditingController controller;

  /// false이면 입력을 받지 않고 글자를 흐리게 그린다.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppBorderWidths.regular,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppLayout.bugReportContentMinHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              enabled: isEnabled,
              inputFormatters: const [
                Utf16LengthLimitingFormatter(
                  BugReportInputLimits.contentMaxLength,
                ),
              ],
              keyboardType: TextInputType.multiline,
              minLines: 6,
              maxLines: null,
              style: AppTextStyles.body14MediumMultiline.copyWith(
                color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintText: '겪으신 문제를 알려 주세요',
                hintStyle: AppTextStyles.body14MediumMultiline.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space16,
                  AppSpacing.space8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                0,
                AppSpacing.space16,
                AppSpacing.space12,
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => Text(
                  '${value.text.length}/${BugReportInputLimits.contentMaxLength}',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption12Medium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
