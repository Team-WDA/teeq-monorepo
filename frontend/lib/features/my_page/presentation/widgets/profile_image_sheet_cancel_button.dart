import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 프로필 사진 시트 아래의 글자만 있는 [취소] 버튼. [onPressed]가 null이면 비활성이다.
class ProfileImageSheetCancelButton extends StatelessWidget {
  const ProfileImageSheetCancelButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      label: '취소',
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: const SizedBox(
          height: AppLayout.textButtonHeight,
          child: Center(child: Text('취소', style: AppTextStyles.body14Medium)),
        ),
      ),
    );
  }
}
