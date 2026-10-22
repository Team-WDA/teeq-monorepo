import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 사진을 더 붙이는 타일. 지금 붙은 장수와 상한을 `n/5`로 함께 보여 준다.
/// 아이콘 없이 글자만 쓴다. [onPressed]가 null이면 비활성이다.
class BugReportAttachmentAddTile extends StatelessWidget {
  const BugReportAttachmentAddTile({
    super.key,
    required this.attachedCount,
    required this.maxCount,
    required this.onPressed,
  });

  final int attachedCount;
  final int maxCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final textColor = isEnabled ? AppColors.textSecondary : AppColors.textMuted;
    return Semantics(
      button: true,
      enabled: isEnabled,
      excludeSemantics: true,
      label: '사진 추가',
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.borderRadiusSm,
            border: Border.all(
              color: AppColors.borderSubtle,
              width: AppBorderWidths.regular,
            ),
          ),
          child: SizedBox(
            width: AppLayout.bugReportAttachmentSize,
            height: AppLayout.bugReportAttachmentSize,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: AppSpacing.space4,
              children: [
                Text(
                  '사진 추가',
                  style: AppTextStyles.caption12Medium.copyWith(
                    color: textColor,
                  ),
                ),
                Text(
                  '$attachedCount/$maxCount',
                  style: AppTextStyles.caption12Medium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
