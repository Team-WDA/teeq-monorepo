import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 토스트 한 개의 외형.
/// 디자인 시안 확정 전 임시: 색, 위치, 모션은 디자이너 명세가 나오면 교체한다.
class AppToast extends StatelessWidget {
  const AppToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // MaterialApp builder 출력에는 기본 글자 스타일(노란 밑줄)이 걸려 있어 Material로 감싼다.
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: AppRadius.borderRadiusMd,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space16),
            child: Text(
              message,
              style: AppTextStyles.body14SemiBoldMultiline.copyWith(
                color: AppColors.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
