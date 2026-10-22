import 'package:flutter/widgets.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel.dart';

/// 패널을 자체 [Overlay] 안에 둔다.
///
/// `MaterialApp.builder` 위치에는 Overlay 조상이 없어서, 입력창과 텍스트 선택이 필요한 패널은
/// 이 Overlay가 있어야 동작한다.
class DebugConsolePanelOverlay extends StatefulWidget {
  const DebugConsolePanelOverlay({super.key});

  @override
  State<DebugConsolePanelOverlay> createState() =>
      _DebugConsolePanelOverlayState();
}

class _DebugConsolePanelOverlayState extends State<DebugConsolePanelOverlay> {
  late final OverlayEntry _panelEntry = OverlayEntry(
    builder: (context) => const DebugConsolePanel(),
  );

  @override
  void dispose() {
    _panelEntry.remove();
    _panelEntry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_panelEntry]);
  }
}
