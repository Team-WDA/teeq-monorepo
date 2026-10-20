import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';

/// 닉네임 변경 화면 상단의 마스코트와 안내 말풍선. 폭이 좁으면 둘 다 비율대로 줄어든다.
class NicknameHelperWithSpeechBubble extends StatelessWidget {
  const NicknameHelperWithSpeechBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space12),
      child: Row(
        children: [
          Expanded(
            flex: AppLayout.nicknameHelperMascotFlex,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: const TeeqMascot(
                pose: TeeqMascotPose.welcome,
                width: AppLayout.nicknameHelperMascotWidth,
              ),
            ),
          ),
          Expanded(
            flex: AppLayout.nicknameHelperBubbleFlex,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppLayout.nicknameHelperBubbleMinHeight,
              ),
              padding: const EdgeInsets.all(AppSpacing.space16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.accentSurface,
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(
                  color: AppColors.accentSoft,
                  width: AppBorderWidths.thin,
                ),
              ),
              child: const Text(
                '어떻게 불러주면 좋을까?\n언제든지 바꿀 수 있어!',
                style: AppTextStyles.body14MediumMultiline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
