import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 로딩 중인 버튼의 접근성 라벨.
const String buttonLoadingSemanticsLabel = '처리 중';

/// 로딩 중인 버튼 안에 글자 대신 놓는 스피너. 접근성 설명은 버튼이 맡으므로 의미 정보를 갖지 않는다.
class ButtonLoadingIndicator extends StatelessWidget {
  const ButtonLoadingIndicator({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: AppLayout.buttonLoadingIndicatorSize,
        height: AppLayout.buttonLoadingIndicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: AppBorderWidths.loadingIndicator,
          color: color,
        ),
      ),
    );
  }
}
