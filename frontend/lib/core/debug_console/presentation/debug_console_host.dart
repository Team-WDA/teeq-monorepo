import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_floating_bubble.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel_controller.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel_overlay.dart';

/// 앱 전체 위에 개발자 콘솔의 버블과 패널을 겹쳐 보여 준다. `MaterialApp.builder`에서 감싼다.
///
/// 개발자 모드가 꺼져 있으면 [child]만 그린다. builder 위치에는 Navigator가 없어
/// 하드웨어 뒤로가기는 [WidgetsBindingObserver.didPopRoute]로 직접 받는다.
class DebugConsoleHost extends ConsumerStatefulWidget {
  const DebugConsoleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DebugConsoleHost> createState() => _DebugConsoleHostState();
}

class _DebugConsoleHostState extends ConsumerState<DebugConsoleHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 패널이 열려 있으면 패널만 닫고, 아니면 앱 라우터가 뒤로가기를 처리하게 둔다.
  @override
  Future<bool> didPopRoute() async {
    final isPanelOpen = ref.read(debugConsolePanelControllerProvider);
    if (!isPanelOpen) {
      return false;
    }
    ref.read(debugConsolePanelControllerProvider.notifier).close();
    return true;
  }

  /// 패널이 열리면 프레임워크가 뒤로가기를 처리한다고 플랫폼에 알린다.
  ///
  /// Android 예측 뒤로가기는 이렇게 알린 동안에만 뒤로가기를 앱으로 넘긴다. 루트 화면에서는
  /// Navigator가 처리할 게 없다고 알려 둔 상태라, 알리지 않으면 뒤로가기가 앱을 백그라운드로
  /// 보내고 패널은 그대로 남는다. 패널을 닫을 때는 되돌리지 않는다: Navigator가 다음 라우트
  /// 변경 때 실제 상태로 다시 알리고, 여기서 임의로 false를 보내면 쌓인 화면의 뒤로가기가
  /// 깨질 수 있다.
  void _announceFrameworkHandlesBack() {
    if (mounted) {
      const NavigationNotification(canHandlePop: true).dispatch(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(debugConsolePanelControllerProvider, (previous, isOpen) {
      if (isOpen) {
        _announceFrameworkHandlesBack();
      }
    });
    final isEnabled = ref.watch(developerModeControllerProvider);
    final isPanelOpen = ref.watch(debugConsolePanelControllerProvider);
    return Stack(
      children: [
        widget.child,
        if (isEnabled) const DebugConsoleFloatingBubble(),
        if (isEnabled && isPanelOpen)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: const DebugConsolePanelOverlay(),
            ),
          ),
      ],
    );
  }
}
