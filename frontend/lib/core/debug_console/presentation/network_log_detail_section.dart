import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 네트워크 호출 상세의 한 구역: 제목과 선택·복사할 수 있는 본문.
class NetworkLogDetailSection extends StatelessWidget {
  const NetworkLogDetailSection({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption12SemiBold.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          SelectableText(text, style: AppTextStyles.monospace12Regular),
        ],
      ),
    );
  }
}
