import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 캐릭터 성향 수정 흐름으로 들어가는 카드. 카드 전체가 눌린다.
class CharacterEditEntryCard extends StatelessWidget {
  const CharacterEditEntryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderRadiusMd,
          side: BorderSide(
            color: AppColors.borderSubtle,
            width: AppBorderWidths.thin,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space14,
            ),
            child: Row(
              children: [
                Image.asset(
                  AppAssets.wandIcon,
                  width: AppLayout.iconSize,
                  height: AppLayout.iconSize,
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('캐릭터 수정', style: AppTextStyles.body14Bold),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        '캐릭터의 성향과 모습을 다시 설정할 수 있어.',
                        style: AppTextStyles.caption12SemiBoldMultiline
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space12),
                SvgPicture.asset(
                  AppAssets.chevronRightIcon,
                  width: AppLayout.iconSize,
                  height: AppLayout.iconSize,
                  colorFilter: const ColorFilter.mode(
                    AppColors.textSecondary,
                    BlendMode.srcIn,
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
