import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 화면 제목과 그 아래 설명 문구.
class ScreenTitleWithDescriptionHeading extends StatelessWidget {
  const ScreenTitleWithDescriptionHeading({
    super.key,
    required this.title,
    required this.description,
    this.titleStyle = AppTextStyles.display32Bold,
    this.titleDescriptionGap = AppSpacing.space12,
  });

  final String title;
  final String description;

  /// 제목 글자 스타일. 기본은 가입 화면들이 쓰는 큰 제목이다.
  final TextStyle titleStyle;

  /// 제목과 설명 사이 간격.
  final double titleDescriptionGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        SizedBox(height: titleDescriptionGap),
        Text(
          description,
          style: AppTextStyles.body14SemiBoldMultiline.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
