import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/ui/button/app_back_button.dart';

/// 본문은 스크롤되고 하단 액션은 고정되는 화면 레이아웃.
/// [onBackPressed]가 있을 때만 상단에 뒤로 가기 버튼을 둔다.
class BottomActionScreenLayout extends StatelessWidget {
  const BottomActionScreenLayout({
    super.key,
    required this.content,
    required this.bottomAction,
    this.onBackPressed,
  });

  final Widget content;
  final Widget bottomAction;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final backPressed = onBackPressed;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (backPressed != null)
              Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(onPressed: backPressed),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.horizontalMargin,
                ),
                child: content,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.horizontalMargin,
                0,
                AppLayout.horizontalMargin,
                AppSpacing.space12,
              ),
              child: bottomAction,
            ),
          ],
        ),
      ),
    );
  }
}
