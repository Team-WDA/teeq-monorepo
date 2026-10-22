import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 목록이 비었을 때 가운데에 보여 주는 문구.
class DebugConsoleEmptyMessage extends StatelessWidget {
  const DebugConsoleEmptyMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Text(
          '기록이 없습니다',
          style: AppTextStyles.body14Medium.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
