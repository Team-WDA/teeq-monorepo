import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 화면 전체 로딩의 접근성 라벨.
const String fullScreenLoadingSemanticsLabel = '불러오는 중';

/// 화면 본문을 대신해 가운데에 스피너 하나만 그리는 전체 로딩 표시.
class FullScreenLoadingIndicator extends StatelessWidget {
  const FullScreenLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: fullScreenLoadingSemanticsLabel,
        child: const SizedBox(
          width: AppLayout.screenLoadingIndicatorSize,
          height: AppLayout.screenLoadingIndicatorSize,
          child: CircularProgressIndicator(
            strokeWidth: AppBorderWidths.loadingIndicator,
            color: AppColors.accentStrong,
          ),
        ),
      ),
    );
  }
}
