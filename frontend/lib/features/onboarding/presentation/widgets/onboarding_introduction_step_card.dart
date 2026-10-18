import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 온보딩 시작 화면에서 앞으로의 단계를 한 줄로 알려 주는 카드.
class OnboardingIntroductionStepCard extends StatelessWidget {
  const OnboardingIntroductionStepCard({
    super.key,
    required this.iconAssetPath,
    required this.message,
  });

  final String iconAssetPath;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppLayout.stepCardHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.accentSoft,
          width: AppBorderWidths.regular,
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            iconAssetPath,
            width: AppLayout.iconSize,
            height: AppLayout.iconSize,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(child: Text(message, style: AppTextStyles.paragraph16)),
        ],
      ),
    );
  }
}
