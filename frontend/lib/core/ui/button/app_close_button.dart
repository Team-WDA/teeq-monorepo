import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 대화상자 모서리의 닫기 버튼. 아이콘은 24px, 탭 영역은 48x48이다. [onPressed]가 null이면 비활성이다.
class AppCloseButton extends StatelessWidget {
  const AppCloseButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: '닫기',
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
              width: AppLayout.dialogCloseIconSize,
              height: AppLayout.dialogCloseIconSize,
              child: Center(child: SvgPicture.asset(AppAssets.closeIcon)),
            ),
          ),
        ),
      ),
    );
  }
}
