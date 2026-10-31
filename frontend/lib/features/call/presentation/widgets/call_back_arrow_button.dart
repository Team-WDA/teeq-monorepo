import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 통화 화면 왼쪽 위의 밝은 뒤로가기 화살표. 어두운 배경 위라 공용 화살표를 흰색으로 칠해 쓴다.
/// 아이콘은 24px, 탭 영역은 48x48이다.
class CallBackArrowButton extends StatelessWidget {
  const CallBackArrowButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '뒤로 가기',
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: AppLayout.minimumTapTarget,
          child: Center(
            child: SvgPicture.asset(
              AppAssets.arrowBackIcon,
              width: AppLayout.iconSize,
              height: AppLayout.iconSize,
              colorFilter: const ColorFilter.mode(
                AppColors.textOnDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
