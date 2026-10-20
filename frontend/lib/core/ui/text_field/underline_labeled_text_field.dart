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
    this.errorMessage,
    this.enabled = true,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// 있으면 밑줄과 이 문구를 오류 색으로 필드 아래에 보인다.
  final String? errorMessage;

  /// false이면 입력과 포커스를 막는다.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body16Bold),
        const SizedBox(height: AppSpacing.space8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: errorMessage == null
                    ? AppColors.borderSubtle
                    : AppColors.destructiveText,
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
              enabled: enabled,
              onChanged: onChanged,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              style: AppTextStyles.body14SemiBold,
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.body14SemiBold.copyWith(
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
        if (errorMessage != null) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            errorMessage!,
            style: AppTextStyles.caption12Medium.copyWith(
              color: AppColors.destructiveText,
            ),
          ),
        ],
      ],
    );
  }
}
