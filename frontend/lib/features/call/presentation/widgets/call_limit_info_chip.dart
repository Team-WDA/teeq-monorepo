import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 한도 안내 카드 안의 시계 아이콘 칩. 문구는 [leadingText] + 강조 [emphasizedText] + [trailingText] 순서로 잇는다.
/// 예: "오늘 남은 통화 시간 " + "12분", "내일 " + "24:00" + "에 통화 시간이 다시 채워져!".
class CallLimitInfoChip extends StatelessWidget {
  const CallLimitInfoChip({
    super.key,
    required this.leadingText,
    required this.emphasizedText,
    this.trailingText = '',
  });

  final String leadingText;
  final String emphasizedText;
  final String trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: AppLayout.callLimitInfoChipHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12 - AppBorderWidths.thin,
        vertical: AppSpacing.space12 - AppBorderWidths.thin,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.accentSoft,
          width: AppBorderWidths.thin,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AppAssets.outlineClockIcon,
            width: AppLayout.smallIconSize,
            height: AppLayout.smallIconSize,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.body14Medium,
                children: [
                  TextSpan(text: leadingText),
                  TextSpan(
                    text: emphasizedText,
                    style: AppTextStyles.body14Bold.copyWith(
                      color: AppColors.accentStrong,
                    ),
                  ),
                  TextSpan(text: trailingText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
