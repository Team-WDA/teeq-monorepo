import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 홈 상단의 인사 카드. 시안 높이는 최소 높이이고 문구가 길면 늘어난다.
class GreetingMessageCard extends StatelessWidget {
  const GreetingMessageCard({super.key, required this.message});

  /// 줄바꿈(`\n`)을 포함할 수 있는 인사 문구.
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.accent,
          width: AppBorderWidths.thin,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppLayout.greetingCardHeight,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space14,
                AppSpacing.space24,
                AppSpacing.space40,
                AppSpacing.space24,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(message, style: AppTextStyles.heading20Bold),
              ),
            ),
            const Positioned(
              top: AppSpacing.space14,
              right: AppSpacing.space14,
              child: _GreetingAccentDot(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingAccentDot extends StatelessWidget {
  const _GreetingAccentDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: AppLayout.greetingDotSize,
      height: AppLayout.greetingDotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
