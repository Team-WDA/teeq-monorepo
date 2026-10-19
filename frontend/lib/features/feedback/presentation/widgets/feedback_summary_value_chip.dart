import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 요약 카드 오른쪽에 놓이는 값 칩. 부모가 정한 폭을 채운다.
class FeedbackSummaryValueChip extends StatelessWidget {
  const FeedbackSummaryValueChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: AppRadius.borderRadiusChip,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space8,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption12SemiBoldMultiline,
        ),
      ),
    );
  }
}
