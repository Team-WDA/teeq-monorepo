import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/checkbox/rounded_square_checkbox.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_option_labels.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_reason_input_field.dart';

/// 통화 시작 이유 체크 목록. "기타"를 고른 동안에만 기타 입력창이 활성이다.
/// 문구에 캐릭터 이름이 들어가는 선택지가 있어 [characterName]을 받는다.
class StartReasonChecklist extends StatelessWidget {
  const StartReasonChecklist({
    super.key,
    required this.characterName,
    required this.selected,
    required this.onToggle,
    required this.otherText,
    required this.onOtherTextChanged,
  });

  static const String otherTextTitle = '기타 이유를 알려줘. (선택)';

  final String characterName;
  final Set<StartReason> selected;
  final ValueChanged<StartReason> onToggle;
  final String otherText;
  final ValueChanged<String> onOtherTextChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.space12,
      children: [
        for (final reason in StartReason.values)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onToggle(reason),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppLayout.startReasonRowHeight,
              ),
              child: Row(
                spacing: AppSpacing.space12,
                children: [
                  RoundedSquareCheckbox(
                    isChecked: selected.contains(reason),
                    onChanged: (_) => onToggle(reason),
                  ),
                  Expanded(
                    child: Text(
                      reason.labelFor(characterName),
                      style: AppTextStyles.body14Medium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        FeedbackReasonInputField(
          title: otherTextTitle,
          text: otherText,
          onChanged: onOtherTextChanged,
          maxLength: FeedbackInputLimits.startReasonOtherTextMaxLength,
          isEnabled: selected.contains(StartReason.other),
        ),
      ],
    );
  }
}
