import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 요약 카드의 한 행. 왼쪽에 아이콘과 라벨, 오른쪽에 고정 폭 값 영역을 둔다.
class FeedbackSummaryRow extends StatelessWidget {
  const FeedbackSummaryRow({
    super.key,
    required this.iconAssetPath,
    required this.label,
    required this.value,
  });

  final String iconAssetPath;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppLayout.summaryRowHeight),
      child: Row(
        spacing: AppSpacing.space12,
        children: [
          Expanded(
            child: Row(
              spacing: AppSpacing.space12,
              children: [
                SvgPicture.asset(
                  iconAssetPath,
                  width: AppLayout.smallIconSize,
                  height: AppLayout.smallIconSize,
                ),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.caption12MediumMultiline,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppLayout.summaryValueWidth, child: value),
        ],
      ),
    );
  }
}
