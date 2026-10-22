import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 테두리가 있는 박스형 입력 필드.
class OutlinedBoxTextField extends StatefulWidget {
  const OutlinedBoxTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChanged,
    this.textInputAction,
    this.inputFormatters,
    this.enabled = true,
    this.hasError = false,
    this.focusedBorderColor,
    this.showClearButton = false,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// false이면 입력과 포커스를 받지 않는다.
  final bool enabled;

  /// true이면 테두리를 오류 색으로 그린다. 포커스 테두리 색보다 우선한다.
  final bool hasError;

  /// 포커스를 받았을 때의 테두리 색. null이면 포커스와 상관없이 기본 테두리 색이다.
  final Color? focusedBorderColor;

  /// true이면 입력이 있을 때 오른쪽에 지우기 버튼을 보인다.
  /// 탭하면 입력을 비우고 `onChanged('')`를 호출한다.
  final bool showClearButton;

  @override
  State<OutlinedBoxTextField> createState() => _OutlinedBoxTextFieldState();
}

class _OutlinedBoxTextFieldState extends State<OutlinedBoxTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(OutlinedBoxTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  Color get _borderColor {
    if (widget.hasError) return AppColors.destructiveText;
    if (_focusNode.hasFocus && widget.focusedBorderColor != null) {
      return widget.focusedBorderColor!;
    }
    return AppColors.borderSubtle;
  }

  @override
  Widget build(BuildContext context) {
    final showClear =
        widget.showClearButton &&
        widget.enabled &&
        widget.controller.text.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: _borderColor, width: AppBorderWidths.regular),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppLayout.outlinedInputHeight,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  enabled: widget.enabled,
                  style: AppTextStyles.body16SemiBold,
                  cursorColor: AppColors.textPrimary,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.body16SemiBold.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showClear) _ClearButton(onPressed: _clear),
        ],
      ),
    );
  }
}

/// 입력 내용을 지우는 버튼. 아이콘은 20px, 탭 영역은 48x48이다.
/// 높이 계산 테스트가 필드의 ConstrainedBox를 찾으므로 IconButton을 쓰지 않는다.
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '입력 지우기',
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: AppLayout.minimumTapTarget,
          height: AppLayout.minimumTapTarget,
          child: Center(
            child: SvgPicture.asset(
              AppAssets.closeIcon,
              width: AppLayout.smallIconSize,
              height: AppLayout.smallIconSize,
              colorFilter: const ColorFilter.mode(
                AppColors.textMuted,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
