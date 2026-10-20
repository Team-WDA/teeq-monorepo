import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_star_rating.dart';

/// 점수를 별 5개로 보여 주는 표시 전용 위젯. 입력은 받지 않는다.
class FeedbackStarDisplay extends StatelessWidget {
  const FeedbackStarDisplay({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppLayout.feedbackStarDisplayGap,
        children: [
          for (var score = 1; score <= FeedbackStarRating.starCount; score++)
            SvgPicture.asset(
              score <= value
                  ? AppAssets.feedbackStarFilledIcon
                  : AppAssets.feedbackStarEmptyIcon,
              width: AppLayout.feedbackStarDisplaySize,
              height: AppLayout.feedbackStarDisplaySize,
            ),
        ],
      ),
    );
  }
}
