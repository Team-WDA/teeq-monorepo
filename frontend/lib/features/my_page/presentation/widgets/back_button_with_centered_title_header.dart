import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';

/// 마이 하위 화면(닉네임 변경, 약관)의 상단에 두는 뒤로 가기 버튼과 가운데 제목.
class BackButtonWithCenteredTitleHeader extends StatelessWidget {
  const BackButtonWithCenteredTitleHeader({
    super.key,
    required this.title,
    required this.onBackPressed,
  });

  final String title;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.minimumTapTarget,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBackButton(onPressed: onBackPressed),
          ),
          // 양쪽 버튼 영역(48)을 피해 긴 제목이 겹치지 않게 한다.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.minimumTapTarget,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading18Medium,
            ),
          ),
        ],
      ),
    );
  }
}
