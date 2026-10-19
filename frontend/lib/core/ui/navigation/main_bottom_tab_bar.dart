import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 홈·마이 화면 아래에 고정되는 하단 탭 바. 높이는 탭 본문 높이에 하단 시스템 인셋을 더한 값이다.
class MainBottomTabBar extends StatelessWidget {
  const MainBottomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: AppColors.tabBarBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.tabBarHorizontalInset,
          0,
          AppLayout.tabBarHorizontalInset,
          bottomInset,
        ),
        child: SizedBox(
          height: AppLayout.tabBarContentHeight,
          child: Row(
            children: [
              Expanded(
                child: _MainBottomTabItem(
                  label: '홈',
                  iconAssetPath: AppAssets.homeTabIcon,
                  isSelected: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
              ),
              Expanded(
                child: _MainBottomTabItem(
                  label: '마이',
                  iconAssetPath: AppAssets.myTabIcon,
                  isSelected: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainBottomTabItem extends StatelessWidget {
  const _MainBottomTabItem({
    required this.label,
    required this.iconAssetPath,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String iconAssetPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.textPrimary : AppColors.textMuted;
    // 시안에서 선택 탭의 글자 굵기가 화면마다 달라, 선택은 SemiBold, 비선택은 Medium으로 정했다.
    final labelStyle =
        (isSelected ? AppTextStyles.caption10 : AppTextStyles.caption10Medium)
            .copyWith(color: color);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: AppLayout.iconSize,
              height: AppLayout.iconSize,
              child: SvgPicture.asset(
                iconAssetPath,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }
}
