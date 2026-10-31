import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/progress/full_screen_loading_indicator.dart';
import 'package:teeq/features/call/domain/call_destination.dart';
import 'package:teeq/features/call/domain/call_phase.dart';
import 'package:teeq/features/call/presentation/call_phase_bottom_content.dart';
import 'package:teeq/features/call/presentation/call_phase_card_overlay.dart';
import 'package:teeq/features/call/presentation/call_phase_status_label.dart';
import 'package:teeq/features/call/presentation/call_session_controller.dart';
import 'package:teeq/features/call/presentation/widgets/call_back_arrow_button.dart';
import 'package:teeq/features/call/presentation/widgets/call_character_background.dart';
import 'package:teeq/features/call/presentation/widgets/call_identity_header.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';

/// 통화 화면. 울리는 중부터 종료까지 모든 단계를 한 화면에서 그린다.
/// 판단은 모두 [CallSessionController]가 하고, 이 화면은 단계별 조립과 뒤로가기·이동 연결만 한다.
/// 컨트롤러는 이 화면이 구독하는 동안만 살아 있고, 화면을 떠나면 방·포그라운드 유지와 함께 정리된다.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  /// 종료 이동을 한 번만 하도록 막는다.
  bool _hasNavigated = false;

  /// 다른 단계에서 울리는 화면으로 돌아온 횟수. 슬라이더 키로 써서 돌아올 때마다 손잡이를 처음 자리로 되돌린다
  /// (받기 실패, 시작 거절 뒤 재시도, 한도 화면의 "다시 통화하기").
  int _ringingEntryCount = 0;

  CallSessionController get _controller =>
      ref.read(callSessionControllerProvider.notifier);

  /// 하드웨어 뒤로가기와 화면의 뒤로가기 화살표가 함께 쓰는 처리. 카드가 떠 있으면 카드의 닫기와 같다.
  void _handleBack() {
    final controller = _controller;
    switch (ref.read(callSessionControllerProvider)) {
      case CallRinging() ||
          CallRequestingPermission() ||
          CallPermissionRequired():
        controller.rejectIncomingCall();
      case CallStarting() || CallConnecting():
        controller.requestEnd();
      case CallInProgress(:final isEndConfirmationVisible):
        if (isEndConfirmationVisible) {
          controller.cancelEnd();
        } else {
          controller.requestEnd();
        }
      case CallConnectionNotice():
        controller.closeConnectionNotice();
      case CallLimitReached(:final callStarted):
        if (callStarted) {
          controller.finishLimitScreenToFeedback();
        } else {
          controller.finishLimitScreenToHome();
        }
      case CallFinished():
        return;
    }
  }

  void _handlePhaseChanged(CallPhase? previous, CallPhase next) {
    if (next is CallRinging && previous is! CallRinging) {
      setState(() => _ringingEntryCount += 1);
    }
    _navigateOnFinished(next);
  }

  void _navigateOnFinished(CallPhase next) {
    if (next is! CallFinished || _hasNavigated || !mounted) {
      return;
    }
    _hasNavigated = true;
    switch (next.destination) {
      case CallDestinationFeedback(:final callSessionId):
        context.pushReplacement(
          AppRoutes.feedbackClosingLocation(callSessionId),
        );
      case CallDestinationHome():
        context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면이 떠 있는 동안 컨트롤러를 붙잡아 둔다.
    final phase = ref.watch(callSessionControllerProvider);
    ref.listen(callSessionControllerProvider, _handlePhaseChanged);
    final memberId = ref.watch(
      currentMemberControllerProvider.select((member) => member?.memberId),
    );
    final HomeSummary? summary;
    if (memberId == null) {
      summary = null;
    } else {
      ref.listen(homeSummaryProvider(memberId), (previous, next) {
        if (next case AsyncError(:final error)) {
          // 홈·피드백 화면과 같이 첫 조회 실패일 때만 막는다.
          ref
              .read(errorHandlerProvider)
              .handle(error, blocking: !next.hasValue);
        }
      });
      summary = ref.watch(homeSummaryProvider(memberId)).value;
    }
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.callScreenBackground,
        body: summary == null
            ? const FullScreenLoadingIndicator()
            : _CallScreenLayers(
                phase: phase,
                summary: summary,
                controller: _controller,
                answerSliderKey: ValueKey(_ringingEntryCount),
                onBackPressed: _handleBack,
              ),
      ),
    );
  }
}

/// 배경 → 상단 이름 → 뒤로가기 → 하단 조작 → (카드 단계면) 어두운 층과 카드 순서로 쌓는다.
class _CallScreenLayers extends StatelessWidget {
  const _CallScreenLayers({
    required this.phase,
    required this.summary,
    required this.controller,
    required this.answerSliderKey,
    required this.onBackPressed,
  });

  final CallPhase phase;
  final HomeSummary summary;
  final CallSessionController controller;
  final Key answerSliderKey;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: CallCharacterBackground(
            characterType: summary.characterType,
            characterMood: summary.characterMood,
          ),
        ),
        SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: AppLayout.callIdentityHeaderTopOffset,
                left: AppLayout.horizontalMargin,
                right: AppLayout.horizontalMargin,
                child: CallIdentityHeader(
                  characterName: summary.characterName,
                  statusLabel: callPhaseStatusLabel(phase),
                ),
              ),
              Positioned(
                top: AppLayout.callBackButtonTopOffset,
                left: AppLayout.callBackButtonLeftOffset,
                child: CallBackArrowButton(onPressed: onBackPressed),
              ),
              CallPhaseBottomContent(
                phase: phase,
                controller: controller,
                answerSliderKey: answerSliderKey,
              ),
            ],
          ),
        ),
        CallPhaseCardOverlay(
          phase: phase,
          characterName: summary.characterName,
          controller: controller,
        ),
      ],
    );
  }
}
