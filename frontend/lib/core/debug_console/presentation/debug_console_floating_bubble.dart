import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/debug_console/presentation/bubble_position.dart';
import 'package:teeq/core/debug_console/presentation/debug_console_panel_controller.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';

/// 화면 위에 떠 있는 둥근 버블. 끌어서 옮기고, 누르면 패널을 연다.
///
/// 패널의 Overlay·Material 바깥에 있으므로 `IconButton`·`Tooltip`·`InkWell`을 쓰지 않는다.
/// 반드시 [Stack]의 직속 자식으로 둔다.
class DebugConsoleFloatingBubble extends ConsumerStatefulWidget {
  const DebugConsoleFloatingBubble({super.key});

  @override
  ConsumerState<DebugConsoleFloatingBubble> createState() =>
      _DebugConsoleFloatingBubbleState();
}

class _DebugConsoleFloatingBubbleState
    extends ConsumerState<DebugConsoleFloatingBubble> {
  static const double _diameter = AppSpacing.space52;

  Offset? _offset;

  Offset _clamp(Offset offset) {
    final media = MediaQuery.of(context);
    return clampBubbleOffset(
      offset: offset,
      screenSize: media.size,
      safePadding: media.padding,
      bubbleDiameter: _diameter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final initialOffset = Offset(
      screenSize.width - _diameter - AppSpacing.space8,
      screenSize.height * 0.6,
    );
    final offset = _clamp(_offset ?? initialOffset);
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Semantics(
        button: true,
        label: '개발자 콘솔 열기',
        child: GestureDetector(
          onPanUpdate: (details) =>
              setState(() => _offset = _clamp(offset + details.delta)),
          onTap: ref.read(debugConsolePanelControllerProvider.notifier).open,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: _diameter,
              child: Icon(
                Icons.bug_report,
                size: AppLayout.iconSize,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
