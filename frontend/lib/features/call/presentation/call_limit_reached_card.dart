import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/features/call/data/call_repository_impl.dart';
import 'package:teeq/features/call/domain/call_limit_kind.dart';
import 'package:teeq/features/call/domain/call_limit_status.dart';
import 'package:teeq/features/call/presentation/call_remaining_time_format.dart';
import 'package:teeq/features/call/presentation/widgets/call_limit_info_chip.dart';
import 'package:teeq/features/call/presentation/widgets/call_status_card.dart';

/// 한도 소진 안내 카드. 1회 한도(per_call)는 카드가 처음 보일 때 오늘 남은 통화 시간을 한 번 조회해 칩에 보여 준다.
/// 조회 중에는 칩 자리를 비워 두고, 실패하면 칩을 숨긴다(에러 화면을 띄우지 않는다).
/// 통화가 시작되지 않은 경우(통화 시작 API가 거절)는 "홈으로 돌아가기" 버튼 하나만 둔다.
class CallLimitReachedCard extends ConsumerStatefulWidget {
  const CallLimitReachedCard({
    super.key,
    required this.limitKind,
    required this.callStarted,
    required this.characterName,
    required this.onFeedbackPressed,
    required this.onHomePressed,
    required this.onCallAgainPressed,
  });

  final CallLimitKind limitKind;
  final bool callStarted;
  final String characterName;
  final VoidCallback onFeedbackPressed;
  final VoidCallback onHomePressed;
  final VoidCallback onCallAgainPressed;

  @override
  ConsumerState<CallLimitReachedCard> createState() =>
      _CallLimitReachedCardState();
}

class _CallLimitReachedCardState extends ConsumerState<CallLimitReachedCard> {
  static const String _logName = 'CallLimitReachedCard';
  static const String _homeLabel = '홈으로 돌아가기';
  static const String _feedbackLabel = '피드백 남기기';

  CallLimitStatus? _todayLimitStatus;
  bool _isLoadingTodayLimitStatus = false;

  @override
  void initState() {
    super.initState();
    if (widget.limitKind == CallLimitKind.perCall) {
      _isLoadingTodayLimitStatus = true;
      unawaited(_loadTodayLimitStatus());
    }
  }

  Future<void> _loadTodayLimitStatus() async {
    try {
      final status = await ref
          .read(callRepositoryProvider)
          .fetchTodayLimitStatus();
      if (mounted) {
        setState(() {
          _todayLimitStatus = status;
          _isLoadingTodayLimitStatus = false;
        });
      }
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      // 칩은 보조 정보라 실패해도 중앙 에러 처리로 넘기지 않고 칩만 숨긴다.
      ref
          .read(appLoggerProvider)
          .log(
            '오늘 남은 통화 시간 조회 실패: ${error.runtimeType}',
            name: _logName,
            level: AppLogLevel.warning,
          );
      setState(() => _isLoadingTodayLimitStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final characterName = widget.characterName;
    final (title, body, chip) = switch (widget.limitKind) {
      CallLimitKind.perCall => (
        '이번 통화 시간이 다 됐어',
        '한 번에 통화할 수 있는 시간이 끝났어. 오늘 남은 시간으로 다시 통화할 수 있어.',
        _todayRemainingTimeChip(),
      ),
      CallLimitKind.perDay => (
        '오늘 통화 시간이 다 됐어',
        '오늘 쓸 수 있는 통화 시간을 모두 썼어. '
            '내일 다시 ${withTogetherParticle(characterName)} 이야기하자!',
        const CallLimitInfoChip(
          leadingText: '내일 ',
          emphasizedText: '24:00',
          trailingText: '에 통화 시간이 다시 채워져!',
        ),
      ),
      // 임시 문구, 디자이너 확인 필요
      CallLimitKind.wholeService => (
        '이번 달 통화 시간이 모두 끝났어',
        '이번 달 ${withSubjectParticle(characterName)} 들려줄 수 있는 통화 시간이 모두 끝났어. '
            '다음 달에 다시 이야기하자.',
        const CallLimitInfoChip(
          leadingText: '',
          emphasizedText: '다음 달 1일',
          trailingText: '에 다시 통화할 수 있어',
        ),
      ),
    };
    if (!widget.callStarted) {
      return CallStatusCard(
        title: title,
        body: body,
        infoChip: chip,
        primaryLabel: _homeLabel,
        onPrimaryPressed: widget.onHomePressed,
      );
    }
    final isPerCall = widget.limitKind == CallLimitKind.perCall;
    return CallStatusCard(
      title: title,
      body: body,
      infoChip: chip,
      primaryLabel: _feedbackLabel,
      onPrimaryPressed: widget.onFeedbackPressed,
      secondaryLabel: isPerCall ? '다시 통화하기' : _homeLabel,
      onSecondaryPressed: isPerCall
          ? widget.onCallAgainPressed
          : widget.onHomePressed,
    );
  }

  /// 조회 중이면 칩 높이만큼 비워 두고, 실패하면 칩을 넣지 않는다.
  Widget? _todayRemainingTimeChip() {
    if (_isLoadingTodayLimitStatus) {
      return const SizedBox(height: AppLayout.callLimitInfoChipHeight);
    }
    final status = _todayLimitStatus;
    if (status == null) {
      return null;
    }
    return CallLimitInfoChip(
      leadingText: '오늘 남은 통화 시간 ',
      emphasizedText: formatTodayRemainingMinutes(status.remainingSeconds),
    );
  }
}
