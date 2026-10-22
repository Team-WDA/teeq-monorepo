import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';

/// 공용 바텀시트를 띄운다. 껍데기(반경, 배경, 핸들, 스크림, 안전 영역, 닫기 정책)만 맡고
/// 내용·안쪽 여백·높이는 [builder]가 정한다.
///
/// [isDismissible]은 스크림 탭과 시스템 뒤로가기로 닫는 것을, [enableDrag]는 아래로 끌어 닫는 것을 허용한다.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.scrimSoft,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (sheetContext) => PopScope(
      // 스크림 탭은 막혀도 시스템 뒤로가기는 시트를 닫으므로 따로 막는다.
      canPop: isDismissible,
      child: AppBottomSheetFrame(child: builder(sheetContext)),
    ),
  );
}

/// 바텀시트 껍데기. 위쪽 둥근 모서리 배경, 상단 핸들, 하단 안전 영역을 그린다.
class AppBottomSheetFrame extends StatelessWidget {
  const AppBottomSheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusLg),
        ),
      ),
      child: Stack(
        children: [
          SafeArea(top: false, child: child),
          const Positioned(
            top: AppLayout.sheetHandleTopOffset,
            left: 0,
            right: 0,
            child: Center(child: _AppBottomSheetHandle()),
          ),
        ],
      ),
    );
  }
}

class _AppBottomSheetHandle extends StatelessWidget {
  const _AppBottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox(
        width: AppLayout.sheetHandleWidth,
        height: AppLayout.sheetHandleHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.textMuted,
            borderRadius: AppRadius.borderRadiusHandle,
          ),
        ),
      ),
    );
  }
}
