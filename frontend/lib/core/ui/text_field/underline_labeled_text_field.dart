import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 라벨이 위에 있고 하단 밑줄만 보이는 입력 필드.
class UnderlineLabeledTextField extends StatelessWidget {
  const UnderlineLabeledTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label16),
        const SizedBox(height: AppSpacing.space8),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderSubtle,
                width: AppBorderWidths.thin,
              ),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppLayout.inputFieldHeight,
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              style: AppTextStyles.paragraph14,
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.paragraph14.copyWith(
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
