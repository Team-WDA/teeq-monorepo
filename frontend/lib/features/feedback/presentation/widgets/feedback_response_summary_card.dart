import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_option_labels.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_star_display.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_summary_row.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_summary_value_chip.dart';

/// 필수 피드백 응답 요약 카드. 첫 통화처럼 [previousCallRecall]이 없으면 "기억한 내용" 행을 그리지 않는다.
class FeedbackResponseSummaryCard extends StatelessWidget {
  const FeedbackResponseSummaryCard({
    super.key,
    required this.rating,
    required this.revisitIntention,
    this.previousCallRecall,
    required this.awkwardMoments,
  });

  final int rating;
  final RevisitIntention revisitIntention;
  final PreviousCallRecall? previousCallRecall;
  final Set<AwkwardMoment> awkwardMoments;

  @override
  Widget build(BuildContext context) {
    final recall = previousCallRecall;
    // 선택한 순서와 상관없이 선택지 선언 순서로 보여 준다.
    final orderedAwkwardMoments = [
      for (final moment in AwkwardMoment.values)
        if (awkwardMoments.contains(moment)) moment,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.accentSoft,
          width: AppBorderWidths.regular,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.space12,
          children: [
            FeedbackSummaryRow(
              iconAssetPath: AppAssets.outlineConversationIcon,
              label: '오늘 통화 만족도',
              value: Align(
                alignment: Alignment.centerRight,
                child: FeedbackStarDisplay(value: rating),
              ),
            ),
            FeedbackSummaryRow(
              iconAssetPath: AppAssets.outlineHeartIcon,
              label: '다시 통화할 의향',
              value: FeedbackSummaryValueChip(label: revisitIntention.label),
            ),
            if (recall != null)
              FeedbackSummaryRow(
                iconAssetPath: AppAssets.outlineClockIcon,
                label: '기억한 내용',
                value: FeedbackSummaryValueChip(label: recall.label),
              ),
            FeedbackSummaryRow(
              iconAssetPath: AppAssets.outlineSparkleIcon,
              label: '어색했던 순간',
              value: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.space4,
                children: [
                  for (final moment in orderedAwkwardMoments)
                    FeedbackSummaryValueChip(label: moment.label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
