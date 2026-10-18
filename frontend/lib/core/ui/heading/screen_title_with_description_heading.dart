import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 화면 제목과 그 아래 설명 문구.
class ScreenTitleWithDescriptionHeading extends StatelessWidget {
  const ScreenTitleWithDescriptionHeading({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.display),
        const SizedBox(height: AppSpacing.space12),
        Text(
          description,
          style: AppTextStyles.paragraph14.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
