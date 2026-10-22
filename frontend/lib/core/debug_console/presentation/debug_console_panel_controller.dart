import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_console_panel_controller.g.dart';

/// 디버그 콘솔 패널이 열려 있는지 보관한다.
@Riverpod(keepAlive: true)
class DebugConsolePanelController extends _$DebugConsolePanelController {
  @override
  bool build() => false;

  void open() => state = true;

  void close() => state = false;
}
