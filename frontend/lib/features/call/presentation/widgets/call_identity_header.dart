import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 통화 화면 상단의 상태 문구와 캐릭터 이름. 상태 문구 자리에는 "TeeQ", "연결중", 통화 경과 시간(`mm:ss`),
/// "연결 실패" 같은 단계별 문구가 들어간다.
class CallIdentityHeader extends StatelessWidget {
  const CallIdentityHeader({
    super.key,
    required this.characterName,
    required this.statusLabel,
  });

  final String characterName;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusLabel,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading20Medium.copyWith(
            color: AppColors.textOnDarkSubtle,
          ),
        ),
        Text(
          characterName,
          textAlign: TextAlign.center,
          style: AppTextStyles.display32Bold.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
      ],
    );
  }
}
