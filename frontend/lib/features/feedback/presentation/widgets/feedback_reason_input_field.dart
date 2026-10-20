import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';

/// 이유를 적는 테두리 상자. 비어 있을 때 [title]과 [example]을 두 줄 안내로 보여 주고,
/// 입력을 시작하면 안내는 사라진다. 글자 수는 [maxLength]로 제한한다.
class FeedbackReasonInputField extends StatefulWidget {
  const FeedbackReasonInputField({
    super.key,
    required this.title,
    this.example,
    required this.text,
    required this.onChanged,
    required this.maxLength,
    this.isEnabled = true,
  });

  final String title;
  final String? example;
  final String text;
  final ValueChanged<String> onChanged;
  final int maxLength;

  /// false이면 입력을 받지 않고 안내 글자를 흐리게 그린다.
  final bool isEnabled;

  @override
  State<FeedbackReasonInputField> createState() =>
      _FeedbackReasonInputFieldState();
}

class _FeedbackReasonInputFieldState extends State<FeedbackReasonInputField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(FeedbackReasonInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 백엔드와 같은 UTF-16 코드 유닛 기준으로 입력을 자른다.
  TextEditingValue _limitLength(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final limited = FeedbackInputLimits.truncate(
      newValue.text,
      widget.maxLength,
    );
    if (limited == newValue.text) {
      return newValue;
    }
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset.clamp(0, limited.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.isEnabled;
    final example = widget.example;
    final mutedColor = isEnabled
        ? AppColors.textSecondary
        : AppColors.textMuted;
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
          minHeight: AppLayout.feedbackReasonInputHeight,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            label: widget.title,
            hint: example,
            child: TextField(
              controller: _controller,
              enabled: isEnabled,
              onChanged: widget.onChanged,
              inputFormatters: [TextInputFormatter.withFunction(_limitLength)],
              minLines: 1,
              maxLines: null,
              style: AppTextStyles.caption12MediumMultiline.copyWith(
                color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                // 안내 글자는 위 Semantics가 이름과 힌트로 읽어 주므로 중복해서 읽지 않게 제외한다.
                hint: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.space4,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.caption12MediumMultiline.copyWith(
                          color: mutedColor,
                        ),
                      ),
                      if (example != null)
                        Text(
                          example,
                          style: AppTextStyles.caption12RegularMultiline
                              .copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.all(AppSpacing.space12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
