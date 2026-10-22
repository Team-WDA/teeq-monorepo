import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 콘솔 헤더·도구 줄에 쓰는 아이콘 버튼. 동작이 끝나기 전의 추가 탭은 무시한다.
class DebugConsoleIconActionButton extends StatefulWidget {
  const DebugConsoleIconActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String tooltip;
  final Future<void> Function() onPressed;

  /// 비활성처럼 보이게 하려면 흐린 색을 넘긴다. 탭은 그대로 받는다.
  final Color iconColor;

  @override
  State<DebugConsoleIconActionButton> createState() =>
      _DebugConsoleIconActionButtonState();
}

class _DebugConsoleIconActionButtonState
    extends State<DebugConsoleIconActionButton> {
  bool _isRunning = false;

  Future<void> _handlePressed() async {
    if (_isRunning) {
      return;
    }
    _isRunning = true;
    try {
      await widget.onPressed();
    } finally {
      _isRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _handlePressed,
      tooltip: widget.tooltip,
      icon: Icon(
        widget.icon,
        size: AppLayout.iconSize,
        color: widget.iconColor,
      ),
    );
  }
}
