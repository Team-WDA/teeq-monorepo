import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel_controller.dart';
import 'package:teeq/core/ui/button/destructive_tonal_button.dart';

/// 개발자 모드를 끄고 패널을 닫는다. 끄는 동안의 추가 탭은 무시한다.
class DeveloperModeDisableButton extends ConsumerStatefulWidget {
  const DeveloperModeDisableButton({super.key});

  @override
  ConsumerState<DeveloperModeDisableButton> createState() =>
      _DeveloperModeDisableButtonState();
}

class _DeveloperModeDisableButtonState
    extends ConsumerState<DeveloperModeDisableButton> {
  bool _isDisabling = false;

  Future<void> _disable() async {
    if (_isDisabling) {
      return;
    }
    _isDisabling = true;
    // 패널이 닫히면 이 위젯도 사라지므로 필요한 것을 먼저 읽어 둔다.
    final developerModeController = ref.read(
      developerModeControllerProvider.notifier,
    );
    ref.read(debugConsolePanelControllerProvider.notifier).close();
    await developerModeController.disable();
  }

  @override
  Widget build(BuildContext context) {
    return DestructiveTonalButton(label: '개발자 모드 끄기', onPressed: _disable);
  }
}
