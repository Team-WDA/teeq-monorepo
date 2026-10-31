import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 통화중 화면 하단의 스피커·종료·음소거 버튼 줄. 부모 폭 양 끝에 스피커와 음소거를, 가운데에 종료를 놓는다.
/// 시안에는 켜짐·꺼짐 외형이 따로 없어 [isSpeakerOn]과 [isMuted]는 접근성 토글 상태로만 알린다.
class CallControlsBar extends StatelessWidget {
  const CallControlsBar({
    super.key,
    required this.isSpeakerOn,
    required this.isMuted,
    required this.onSpeakerPressed,
    required this.onEndPressed,
    required this.onMutePressed,
  });

  final bool isSpeakerOn;
  final bool isMuted;
  final VoidCallback onSpeakerPressed;
  final VoidCallback onEndPressed;
  final VoidCallback onMutePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CallControlButton(
          label: '스피커',
          iconAsset: AppAssets.callSpeakerIcon,
          backgroundAsset: AppAssets.callControlBackground,
          isToggled: isSpeakerOn,
          onPressed: onSpeakerPressed,
        ),
        _CallControlButton(
          label: '종료',
          iconAsset: AppAssets.callEndIcon,
          backgroundAsset: AppAssets.callEndControlBackground,
          onPressed: onEndPressed,
        ),
        _CallControlButton(
          label: '음소거',
          iconAsset: AppAssets.callMuteIcon,
          backgroundAsset: AppAssets.callControlBackground,
          isToggled: isMuted,
          onPressed: onMutePressed,
        ),
      ],
    );
  }
}

/// 원형 배경 위 글리프와 아래 문구로 된 통화 버튼 하나. [isToggled]가 null이면 토글이 아닌 버튼이다.
class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundAsset,
    required this.onPressed,
    this.isToggled,
  });

  final String label;
  final String iconAsset;
  final String backgroundAsset;
  final VoidCallback onPressed;
  final bool? isToggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: isToggled,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: AppLayout.callControlButtonSize,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: AppLayout.callControlButtonSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SvgPicture.asset(backgroundAsset),
                    SizedBox.square(
                      dimension: AppLayout.callControlIconBoxSize,
                      child: Center(child: SvgPicture.asset(iconAsset)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption12SemiBold.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
