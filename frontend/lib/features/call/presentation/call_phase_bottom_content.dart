import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/features/call/domain/call_phase.dart';
import 'package:teeq/features/call/presentation/call_session_controller.dart';
import 'package:teeq/features/call/presentation/widgets/call_controls_bar.dart';
import 'package:teeq/features/call/presentation/widgets/call_slide_to_answer.dart';

/// 통화 화면 하단의 단계별 조작. 울리는 중에는 밀어서 받기, 연결중·통화중에는 컨트롤 줄을 놓는다.
/// 통화 화면 [Stack] 안에서 [Positioned]로 자리를 잡는다.
class CallPhaseBottomContent extends StatelessWidget {
  const CallPhaseBottomContent({
    super.key,
    required this.phase,
    required this.controller,
    required this.answerSliderKey,
  });

  final CallPhase phase;
  final CallSessionController controller;

  /// 울리는 화면에 다시 들어올 때마다 바뀌는 키. 받기가 실패해 돌아오면 슬라이더를 새로 만들어 처음 자리로 되돌린다.
  final Key answerSliderKey;

  @override
  Widget build(BuildContext context) {
    return switch (phase) {
      CallRinging() || CallRequestingPermission() => Positioned(
        left: AppLayout.callSlideToAnswerHorizontalInset,
        right: AppLayout.callSlideToAnswerHorizontalInset,
        bottom: AppLayout.callSlideToAnswerBottomOffset,
        // 권한 확인 중에는 컨트롤러도 막지만 슬라이더 입력 자체를 받지 않는다.
        child: IgnorePointer(
          ignoring: phase is CallRequestingPermission,
          child: CallSlideToAnswer(
            key: answerSliderKey,
            onCompleted: () => unawaited(controller.answer()),
          ),
        ),
      ),
      // 워커가 보이기 전에는 종료만 동작한다(확인 없이 끝난다). 스피커·음소거는 누를 수만 있다.
      CallStarting() || CallConnecting() => _controls(
        CallControlsBar(
          isSpeakerOn: false,
          isMuted: false,
          onSpeakerPressed: _ignorePress,
          onEndPressed: controller.requestEnd,
          onMutePressed: _ignorePress,
        ),
      ),
      CallInProgress(:final isSpeakerOn, :final isMuted) => _controls(
        CallControlsBar(
          isSpeakerOn: isSpeakerOn,
          isMuted: isMuted,
          onSpeakerPressed: () => unawaited(controller.toggleSpeaker()),
          onEndPressed: controller.requestEnd,
          onMutePressed: () => unawaited(controller.toggleMute()),
        ),
      ),
      CallPermissionRequired() ||
      CallConnectionNotice() ||
      CallLimitReached() ||
      CallFinished() => const SizedBox.shrink(),
    };
  }

  Widget _controls(CallControlsBar controlsBar) => Positioned(
    left: AppLayout.callControlsHorizontalInset,
    right: AppLayout.callControlsHorizontalInset,
    bottom: AppLayout.callControlsBottomOffset,
    child: controlsBar,
  );

  static void _ignorePress() {}
}
