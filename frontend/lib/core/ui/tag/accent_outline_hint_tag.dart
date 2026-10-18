import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 강조색 테두리의 알약형 안내 태그.
class AccentOutlineHintTag extends StatelessWidget {
  const AccentOutlineHintTag({super.key, required this.message, this.maxLines});

  final String message;

  /// 지정하면 문구를 이 줄 수까지만 보이고 넘치면 말줄임한다. null이면 줄바꿈한다.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.borderRadiusLg,
        border: Border.all(
          color: AppColors.accent,
          width: AppBorderWidths.regular,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppLayout.hintTagHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space10,
            vertical: AppSpacing.space4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppLayout.iconSize,
                height: AppLayout.iconSize,
                child: Center(child: SvgPicture.asset(AppAssets.sparkleIcon)),
              ),
              const SizedBox(width: AppSpacing.space8),
              Flexible(
                child: Text(
                  message,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: AppTextStyles.paragraph14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
