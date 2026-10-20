import 'package:flutter/widgets.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot.dart';
import 'package:teeq/core/ui/illustration/teeq_mascot_pose.dart';

/// 상세 피드백 초대 시트 아래쪽 장식. 타원 빛 번짐 위에 마스코트를 얹고 영역 밖은 잘라 낸다.
/// 본문 폭에 비례해 균일하게 커지고 작아진다.
class InvitationSheetDecoration extends StatelessWidget {
  const InvitationSheetDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / AppLayout.designContentWidth;
        return SizedBox(
          height: AppLayout.invitationDecorationHeight * scale,
          child: Stack(
            children: [
              Positioned(
                left: AppLayout.invitationGlowOffsetX * scale,
                top: AppLayout.invitationGlowOffsetY * scale,
                child: SoftGlowDecoration(
                  assetPath: AppAssets.feedbackGlowEllipse,
                  width: AppLayout.invitationGlowWidth * scale,
                  height: AppLayout.invitationGlowHeight * scale,
                ),
              ),
              Positioned(
                left: AppLayout.invitationMascotOffsetX * scale,
                top: AppLayout.invitationMascotOffsetY * scale,
                child: TeeqMascot(
                  pose: TeeqMascotPose.welcome,
                  width: AppLayout.invitationMascotWidth * scale,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
