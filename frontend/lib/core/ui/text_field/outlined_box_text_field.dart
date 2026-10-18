import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 테두리가 있는 박스형 입력 필드.
class OutlinedBoxTextField extends StatelessWidget {
  const OutlinedBoxTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.onChanged,
    this.textInputAction,
    this.inputFormatters,
    this.enabled = true,
  });

  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;

  /// false이면 입력과 포커스를 받지 않는다.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: AppBorderWidths.regular,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppLayout.outlinedInputHeight,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            enabled: enabled,
            style: AppTextStyles.paragraph16,
            cursorColor: AppColors.textPrimary,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.paragraph16.copyWith(
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
    );
  }
}
