import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_choice_group.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_reason_input_field.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';

/// 1~5점 점수 문항 한 개. 제목, 1·3·5점 설명 라벨, 점수 칩, 이유 입력, 선택적 하단 위젯으로 이룬다.
/// 각 구간은 점수 숫자(1·3·5) 아래에 라벨을 둔다. 라벨은 폭이 좁아도 겹치지 않도록 1점은 왼쪽, 3점은 가운데, 5점은 오른쪽 정렬로 세 구간에 나눈다.
class ScaledQuestionSection extends StatelessWidget {
  const ScaledQuestionSection({
    super.key,
    required this.title,
    required this.anchorLabels,
    required this.score,
    required this.onScoreChanged,
    required this.reasonText,
    required this.onReasonChanged,
    required this.reasonExample,
    this.isScoreEnabled = true,
    this.footer,
  }) : assert(anchorLabels.length == 3);

  static const List<int> scores = [1, 2, 3, 4, 5];
  static const String reasonTitle = '이유를 한 줄로 알려줘. (선택)';

  final String title;

  /// 1·3·5점에 해당하는 설명 라벨. 길이는 3이다.
  final List<String> anchorLabels;
  final int? score;
  final ValueChanged<int> onScoreChanged;
  final String reasonText;
  final ValueChanged<String> onReasonChanged;
  final String reasonExample;

  /// false이면 점수 칩과 이유 입력이 모두 비활성이다.
  final bool isScoreEnabled;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footerWidget = footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.space8,
      children: [
        Text(title, style: AppTextStyles.body16BoldMultiline),
        Row(
          spacing: AppSpacing.space8,
          children: [
            _anchorCell(1, anchorLabels[0], TextAlign.left),
            _anchorCell(3, anchorLabels[1], TextAlign.center),
            _anchorCell(5, anchorLabels[2], TextAlign.right),
          ],
        ),
        FeedbackChoiceGroup<int>(
          values: scores,
          labelOf: (value) => '$value',
          selectedValues: {?score},
          onTap: onScoreChanged,
          columnCount: scores.length,
          isEnabled: isScoreEnabled,
        ),
        FeedbackReasonInputField(
          title: reasonTitle,
          example: reasonExample,
          text: reasonText,
          onChanged: onReasonChanged,
          maxLength: FeedbackInputLimits.reasonMaxLength,
          isEnabled: isScoreEnabled,
        ),
        ?footerWidget,
      ],
    );
  }

  /// 점수 숫자를 윗줄에, 설명 라벨을 아랫줄에 두는 한 구간.
  Widget _anchorCell(int anchorScore, String label, TextAlign textAlign) {
    final anchorStyle = AppTextStyles.caption12RegularMultiline.copyWith(
      color: AppColors.textSecondary,
    );
    return Expanded(
      child: Column(
        crossAxisAlignment: switch (textAlign) {
          TextAlign.center => CrossAxisAlignment.center,
          TextAlign.right => CrossAxisAlignment.end,
          _ => CrossAxisAlignment.start,
        },
        children: [
          Text('$anchorScore', textAlign: textAlign, style: anchorStyle),
          Text(label, textAlign: textAlign, style: anchorStyle),
        ],
      ),
    );
  }
}
