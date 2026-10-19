import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';

/// 필수 피드백 시트 머리말. 왼쪽에 제목과 부제, 오른쪽에 마스코트를 둔다.
class RequiredFeedbackSheetHeader extends StatelessWidget {
  const RequiredFeedbackSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.space8,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.space8,
            children: [
              const Text('오늘 통화는 어땠어?', style: AppTextStyles.title24Bold),
              Text(
                '네 이야기를 듣고 더 좋은 친구가 될게.',
                style: AppTextStyles.caption12SemiBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const TeeqMascot(
          pose: TeeqMascotPose.welcome,
          width: AppLayout.requiredSheetMascotWidth,
        ),
      ],
    );
  }
}
