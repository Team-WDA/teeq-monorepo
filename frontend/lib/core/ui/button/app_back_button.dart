import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 화면 상단의 뒤로 가기 버튼. 아이콘은 24px, 탭 영역은 48x48이다.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});

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
        child: SizedBox(
          width: AppLayout.minimumTapTarget,
          height: AppLayout.minimumTapTarget,
          child: Center(
            child: SizedBox(
              width: AppLayout.iconSize,
              height: AppLayout.iconSize,
              child: SvgPicture.asset(AppAssets.arrowBackIcon),
            ),
          ),
        ),
      ),
    );
  }
}
