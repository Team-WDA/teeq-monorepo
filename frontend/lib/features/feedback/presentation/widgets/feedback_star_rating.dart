import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 별 5개로 점수를 고른다. 같은 별을 다시 눌러도 값은 0이 되지 않고 그대로 전달된다.
/// 첫 별과 마지막 별은 양끝에 붙이고, 각 별의 터치 영역은 최소 터치 크기를 보장한다.
class FeedbackStarRating extends StatelessWidget {
  const FeedbackStarRating({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const int starCount = 5;

  final int? value;
  final ValueChanged<int> onChanged;

  Alignment _alignmentOf(int score) {
    if (score == 1) return Alignment.centerLeft;
    if (score == starCount) return Alignment.centerRight;
    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    final selectedScore = value ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var score = 1; score <= starCount; score++)
          Semantics(
            button: true,
            selected: score == selectedScore,
            label: '별 $score개',
            excludeSemantics: true,
            onTap: () => onChanged(score),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(score),
              child: SizedBox(
                width: AppLayout.minimumTapTarget,
                height: AppLayout.minimumTapTarget,
                child: Align(
                  alignment: _alignmentOf(score),
                  child: SvgPicture.asset(
                    score <= selectedScore
                        ? AppAssets.feedbackStarFilledIcon
                        : AppAssets.feedbackStarEmptyIcon,
                    width: AppLayout.feedbackStarSize,
                    height: AppLayout.feedbackStarSize,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
