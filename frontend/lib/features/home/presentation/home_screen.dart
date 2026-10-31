import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/permission/microphone_permission_prompt.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/progress/full_screen_loading_indicator.dart';
import 'package:teeq/features/home/domain/feedback_flow_path.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/domain/pending_feedback_auto_open_policy.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/home/presentation/widgets/call_start_button.dart';
import 'package:teeq/features/home/presentation/widgets/character_edit_entry_card.dart';
import 'package:teeq/features/home/presentation/widgets/greeting_message_card.dart';
import 'package:teeq/features/home/presentation/widgets/home_character_illustration.dart';
import 'package:teeq/features/home/presentation/widgets/personality_tag_row.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';

/// 홈 화면. 하단 탭 바는 탭 셸이 제공하므로 여기서는 본문만 그린다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEditDialogOpen = false;
  bool _isCallFlowOpening = false;
  GoRouterDelegate? _routerDelegate;
  String? _previousPath;

  /// 피드백 흐름을 닫고 홈으로 돌아온 직후, 그 흐름의 통화 세션 id. 다른 경로로 홈에 오면 null이다.
  String? _lastClosedFeedbackCallSessionId;

  /// 팝업이 떠 있는 동안 같은 카드가 다시 눌려도 팝업을 또 띄우지 않는다.
  Future<void> _openEditDialog(
    String characterName,
    CharacterType characterType,
  ) async {
    if (_isEditDialogOpen) {
      return;
    }
    setState(() => _isEditDialogOpen = true);
    try {
      await showCharacterEditConfirmationDialog(
        context,
        characterName: characterName,
        characterType: characterType,
      );
    } finally {
      if (mounted) {
        setState(() => _isEditDialogOpen = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 라우터가 없는 하네스에서는 구독하지 않는다.
    final routerDelegate = GoRouter.maybeOf(context)?.routerDelegate;
    if (routerDelegate != null) {
      _routerDelegate = routerDelegate;
      _previousPath = _currentPath(routerDelegate);
      routerDelegate.addListener(_refetchWhenReturningToHome);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _requestMicrophonePermissionOnce();
    });
  }

  /// 홈 첫 표시 때 마이크 권한을 한 번 묻는다. 실패해도 홈은 그대로 두고 로그만 남긴다.
  void _requestMicrophonePermissionOnce() {
    final logger = ref.read(appLoggerProvider);
    unawaited(
      ref
          .read(microphonePermissionPromptProvider)
          .requestOnceIfNeeded()
          .catchError((Object error, StackTrace stackTrace) {
            logger.log(
              '마이크 권한 요청 실패',
              name: 'HomeScreen',
              level: AppLogLevel.warning,
              error: error,
              stackTrace: stackTrace,
            );
          }),
    );
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_refetchWhenReturningToHome);
    super.dispose();
  }

  /// 명령형 push로 쌓인 화면까지 반영한 가장 위 경로. `uri`는 push된 화면을 반영하지 않는다.
  String? _currentPath(GoRouterDelegate routerDelegate) {
    final configuration = routerDelegate.currentConfiguration;
    return configuration.isEmpty ? null : configuration.last.matchedLocation;
  }

  /// 홈이 아닌 위치에서 홈으로 돌아오는 순간에만 홈 요약을 다시 조회한다(홈→홈은 무시).
  void _refetchWhenReturningToHome() {
    final routerDelegate = _routerDelegate;
    if (routerDelegate == null) {
      return;
    }
    final previousPath = _previousPath;
    final path = _currentPath(routerDelegate);
    _previousPath = path;
    if (path != AppRoutes.home || previousPath == AppRoutes.home) {
      return;
    }
    // 탭 셸 안의 홈은 위 화면이 `context.go`로 끝나도 isCurrent가 바뀌지 않고 push Future도 끝나지 않으므로,
    // 다른 경로에서 홈으로 돌아오는 순간 흐름 진입 잠금을 푼다.
    _releaseCallFlowOpening();
    // 피드백 흐름에서 돌아왔으면 같은 피드백을 바로 다시 열지 않고, 다른 경로에서 왔으면 다시 열 수 있게 한다.
    _lastClosedFeedbackCallSessionId = previousPath == null
        ? null
        : callSessionIdFromFeedbackPath(previousPath);
    final memberId = ref.read(currentMemberControllerProvider)?.memberId;
    if (memberId == null) {
      return;
    }
    final provider = homeSummaryProvider(memberId);
    // 피드백 흐름 종료 등이 이미 다시 조회 중이면 중복 호출하지 않는다.
    if (ref.read(provider).isLoading) {
      return;
    }
    ref.invalidate(provider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 흐름이 스택을 교체하며 끝나 홈 라우트가 다시 맨 위가 되면, 홈 데이터가 그대로여도 다시 열 수 있어야 한다.
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _releaseCallFlowOpening();
      // 빌드 도중 이동하지 않도록 프레임 뒤에 대기 피드백을 열지 판단한다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openPendingFeedbackIfNeeded();
        }
      });
    }
  }

  /// 대기 피드백이 있고 홈이 맨 위 화면이면 피드백 흐름을 자동으로 연다.
  /// 홈 요약이 다시 조회 중이면 이전 값으로 판단하지 않고 새 값이 도착할 때 다시 판단한다.
  void _openPendingFeedbackIfNeeded() {
    final routerDelegate = _routerDelegate;
    // 라우터가 없는 하네스에서는 이동하지 않는다.
    // 캐릭터 수정 팝업은 루트 Navigator에 떠서 홈이 현재 화면으로 남으므로 따로 막는다.
    if (routerDelegate == null || _isCallFlowOpening || _isEditDialogOpen) {
      return;
    }
    // 탭 셸 안의 홈은 위에 다른 화면이 쌓여도 자기 Navigator에서는 현재 화면이므로 경로도 함께 확인한다.
    final isHomeOnTop =
        (ModalRoute.of(context)?.isCurrent ?? false) &&
        _currentPath(routerDelegate) == AppRoutes.home;
    if (!isHomeOnTop) {
      return;
    }
    final memberId = ref.read(currentMemberControllerProvider)?.memberId;
    if (memberId == null) {
      return;
    }
    final summaryState = ref.read(homeSummaryProvider(memberId));
    if (summaryState.isLoading) {
      return;
    }
    final pendingFeedback = summaryState.value?.pendingFeedback;
    if (pendingFeedback == null ||
        !shouldAutoOpenPendingFeedback(
          pendingFeedback: pendingFeedback,
          lastClosedFeedbackCallSessionId: _lastClosedFeedbackCallSessionId,
        )) {
      return;
    }
    _openFeedbackFlow(pendingFeedback.callSessionId);
  }

  void _openCallFlow() => _pushCallFlowRoute(AppRoutes.call);

  void _openFeedbackFlow(String callSessionId) =>
      _pushCallFlowRoute(AppRoutes.feedbackClosingLocation(callSessionId));

  /// 통화·피드백 흐름을 연다. 흐름은 `context.go`로 스택을 교체하며 끝나 push의 Future가 끝나지 않을 수 있으므로
  /// await하지 않고, 플래그는 Future 완료와 홈 요약 데이터 변경 두 곳에서 내린다.
  void _pushCallFlowRoute(String location) {
    if (_isCallFlowOpening) {
      return;
    }
    _isCallFlowOpening = true;
    unawaited(
      context.push<void>(location).whenComplete(_releaseCallFlowOpening),
    );
  }

  void _releaseCallFlowOpening() {
    _isCallFlowOpening = false;
  }

  @override
  Widget build(BuildContext context) {
    // 로그아웃·탈퇴 순간 회원이 비면 이전 회원 데이터를 지우고 오류 페이지로 새지 않게 비워 둔다.
    final memberId = ref.watch(
      currentMemberControllerProvider.select((member) => member?.memberId),
    );
    if (memberId == null) {
      return const SizedBox.shrink();
    }
    ref.listen(homeSummaryProvider(memberId), (previous, next) {
      if (next case AsyncError(:final error)) {
        // 이전 값이 있으면 화면을 유지한 채 알리기만 하고, 첫 조회 실패일 때만 막는다.
        ref.read(errorHandlerProvider).handle(error, blocking: !next.hasValue);
      }
      // 필수 제출 뒤 홈이 갱신되면 피드백 흐름 진입 잠금을 푼다.
      if (next case AsyncData(:final value) when value != previous?.value) {
        _releaseCallFlowOpening();
      }
      // 새 홈 요약이 도착하면 대기 피드백을 열지 판단한다.
      if (next is AsyncData) {
        _openPendingFeedbackIfNeeded();
      }
    });
    final summaryState = ref.watch(homeSummaryProvider(memberId));
    if (summaryState.isLoading) {
      return const FullScreenLoadingIndicator();
    }
    final summary = summaryState.value;
    if (summary == null) {
      return const SizedBox.shrink();
    }
    return _HomeContent(
      summary: summary,
      onStartCall: _openCallFlow,
      onEditCharacter: () =>
          _openEditDialog(summary.characterName, summary.characterType),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.summary,
    required this.onStartCall,
    required this.onEditCharacter,
  });

  final HomeSummary summary;
  final VoidCallback onStartCall;
  final VoidCallback onEditCharacter;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = EdgeInsets.symmetric(
      horizontal: AppLayout.horizontalMargin,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            // 남는 세로 공간은 세 덩어리 사이에 균등하게 나뉘어 일러스트가 가운데 놓인다.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: horizontalPadding.copyWith(top: AppSpacing.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SvgPicture.asset(
                          AppAssets.brandLogo,
                          width: AppLayout.brandLogoWidth,
                          height: AppLayout.brandLogoHeight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      GreetingMessageCard(message: summary.greeting),
                    ],
                  ),
                ),
                HomeCharacterIllustration(
                  characterType: summary.characterType,
                  characterMood: summary.characterMood,
                ),
                Padding(
                  padding: horizontalPadding.copyWith(
                    top: AppSpacing.space12,
                    bottom: AppSpacing.space20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        summary.characterName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading20Bold,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      PersonalityTagRow(tags: summary.personalityTags),
                      const SizedBox(height: AppSpacing.space24),
                      CallStartButton(onPressed: onStartCall),
                      const SizedBox(height: AppSpacing.space8),
                      CharacterEditEntryCard(onTap: onEditCharacter),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
