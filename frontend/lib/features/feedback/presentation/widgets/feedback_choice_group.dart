import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_choice_chip.dart';

/// 선택지를 같은 폭으로 [columnCount]칸에 나누어 놓고, 칸 수를 넘으면 다음 줄로 넘긴다.
class FeedbackChoiceGroup<T> extends StatelessWidget {
  const FeedbackChoiceGroup({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selectedValues,
    required this.onTap,
    required this.columnCount,
    this.isEnabled = true,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final Set<T> selectedValues;
  final ValueChanged<T> onTap;
  final int columnCount;

  /// false이면 모든 칸이 탭을 무시한다.
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chipWidth =
            (constraints.maxWidth - AppSpacing.space8 * (columnCount - 1)) /
            columnCount;
        return Wrap(
          spacing: AppSpacing.space8,
          runSpacing: AppSpacing.space8,
          children: [
            for (final value in values)
              SizedBox(
                width: chipWidth,
                child: FeedbackChoiceChip(
                  label: labelOf(value),
                  isSelected: selectedValues.contains(value),
                  isEnabled: isEnabled,
                  onTap: () => onTap(value),
                ),
              ),
          ],
        );
      },
    );
  }
}
