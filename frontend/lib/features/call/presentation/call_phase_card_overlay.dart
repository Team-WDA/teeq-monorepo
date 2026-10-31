import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/features/call/domain/call_phase.dart';
import 'package:teeq/features/call/presentation/call_limit_reached_card.dart';
import 'package:teeq/features/call/presentation/call_session_controller.dart';
import 'package:teeq/features/call/presentation/widgets/call_status_card.dart';

/// 카드가 필요한 단계에서 화면 전체를 어둡게 덮고 가운데에 안내 카드를 띄운다. 카드가 없으면 아무것도 그리지 않는다.
/// 버튼은 모두 [controller] 메서드를 부르기만 한다.
class CallPhaseCardOverlay extends StatelessWidget {
  const CallPhaseCardOverlay({
    super.key,
    required this.phase,
    required this.characterName,
    required this.controller,
  });

  final CallPhase phase;
  final String characterName;
  final CallSessionController controller;

  @override
  Widget build(BuildContext context) {
    final card = _card();
    if (card == null) {
      return const SizedBox.shrink();
    }
    // 어두운 층은 아래 화면의 입력도 막는다(ColoredBox는 자기 영역의 터치를 받는다).
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.scrimSoft),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.horizontalMargin,
              ),
              child: card,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _card() => switch (phase) {
    CallRinging() ||
    CallRequestingPermission() ||
    CallStarting() ||
    CallConnecting() ||
    CallFinished() => null,
    CallPermissionRequired() => CallStatusCard(
      title: '마이크 권한이 필요해',
      body:
          '${withConjunctiveParticle(characterName)} 대화를 시작하려면 '
          '마이크 권한을 허용해야 돼.',
      primaryLabel: '권한 허용하기',
      onPrimaryPressed: () =>
          unawaited(controller.retryAfterPermissionRequired()),
      secondaryLabel: '나중에 하기',
      onSecondaryPressed: controller.rejectIncomingCall,
    ),
    final CallInProgress inProgress => _inProgressCard(inProgress),
    CallConnectionNotice(:final kind, :final callStarted) => switch (kind) {
      CallConnectionNoticeKind.connectionFailed => CallStatusCard(
        title: '연결하지 못했어',
        body: '네트워크 상태를 확인하고 다시 연결해줘.',
        primaryLabel: '다시 연결하기',
        onPrimaryPressed: _retryConnection,
        secondaryLabel: callStarted ? '통화 마치기' : '홈으로 돌아가기',
        onSecondaryPressed: controller.closeConnectionNotice,
      ),
      CallConnectionNoticeKind.connectionTimeout => CallStatusCard(
        title: '연결이 지연되고 있어',
        body: '응답을 기다리는 시간이 길어졌어. 잠시 후 다시 시도해줘.',
        primaryLabel: '다시 시도하기',
        onPrimaryPressed: _retryConnection,
        // 연결 실패 카드와 같이 통화가 시작됐으면 피드백으로 가므로 문구를 바꾼다.
        secondaryLabel: callStarted ? '통화 마치기' : '홈으로 돌아가기',
        onSecondaryPressed: controller.closeConnectionNotice,
      ),
      CallConnectionNoticeKind.connectionLost => _reconnectNoticeCard(
        onEndPressed: controller.closeConnectionNotice,
      ),
    },
    CallLimitReached(:final limitKind, :final callStarted) =>
      CallLimitReachedCard(
        limitKind: limitKind,
        callStarted: callStarted,
        characterName: characterName,
        onFeedbackPressed: controller.finishLimitScreenToFeedback,
        onHomePressed: controller.finishLimitScreenToHome,
        onCallAgainPressed: controller.restartAfterLimitReached,
      ),
  };

  /// 통화중 위에 겹치는 카드. 종료 확인 > 재연결 안내 > 곧 종료 순서로 하나만 보인다.
  Widget? _inProgressCard(CallInProgress phase) {
    if (phase.isEndConfirmationVisible) {
      return CallStatusCard(
        title: '통화를 마칠까?',
        primaryLabel: '계속 통화하기',
        onPrimaryPressed: controller.cancelEnd,
        secondaryLabel: '통화 마치기',
        onSecondaryPressed: _confirmEnd,
      );
    }
    if (phase.isReconnectNoticeVisible) {
      return _reconnectNoticeCard(onEndPressed: _confirmEnd);
    }
    if (phase.isEndingSoonVisible) {
      return CallStatusCard(
        title: '통화 시간이 곧 끝나가.',
        body: '마지막으로 하고 싶은 이야기를 나눠줘. 시간이 다 되면 통화가 종료돼.',
        primaryLabel: '계속 이야기하기',
        onPrimaryPressed: controller.dismissEndingSoon,
        secondaryLabel: '지금 마치기',
        onSecondaryPressed: _confirmEnd,
      );
    }
    return null;
  }

  Widget _reconnectNoticeCard({required VoidCallback onEndPressed}) =>
      CallStatusCard(
        title: '연결이 잠시 끊겼어',
        body:
            '${withConjunctiveParticle(characterName)} 다시 연결하고 있어. '
            '네트워크가 안정되면 대화를 이어갈게.',
        primaryLabel: '다시 연결하기',
        onPrimaryPressed: _retryConnection,
        secondaryLabel: '통화 마치기',
        onSecondaryPressed: onEndPressed,
      );

  void _retryConnection() => unawaited(controller.retryConnection());

  void _confirmEnd() => unawaited(controller.confirmEnd());
}
