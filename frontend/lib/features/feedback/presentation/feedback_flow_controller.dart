import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/auth_status.dart';
import 'package:teeq/core/auth/auth_status_controller.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/feedback/data/feedback_repository_impl.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';
import 'package:teeq/features/feedback/presentation/feedback_flow_state.dart';
import 'package:teeq/features/feedback/presentation/feedback_status_retry_policy.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';

part 'feedback_flow_controller.g.dart';

/// 피드백 상태 조회 결과. [ignored]는 이미 요청 중이라 아무것도 보내지 않았다는 뜻이고,
/// [unavailable]은 통화 세션이 없거나 재시도 끝에도 피드백을 받을 수 없어 더 시도해도 소용없다는 뜻이다.
enum FeedbackStatusLoadResult {
  ready,
  alreadySubmitted,
  unavailable,
  failed,
  ignored,
}

/// 필수 피드백 제출 결과. [ignored]는 요청 중이거나 응답이 미완성이라 아무것도 보내지 않았다는 뜻이다.
enum RequiredFeedbackSubmitResult {
  submitted,
  submittedWithInvitation,
  alreadySubmitted,
  failed,
  ignored,
}

/// 상세 피드백 제출 결과. [ignored]는 요청 중이거나 응답이 미완성이라 아무것도 보내지 않았다는 뜻이다.
enum DetailedFeedbackSubmitResult {
  submitted,
  alreadySubmitted,
  failed,
  ignored,
}

/// 피드백 흐름 상태를 보관한다. 진입점이 [start]로 통화를 정하고 흐름이 끝나면 [reset]한다.
@Riverpod(keepAlive: true)
class FeedbackFlowController extends _$FeedbackFlowController {
  /// 흐름이 시작되거나 비워질 때마다 늘어난다. 늦게 도착한 응답이 새 흐름을 건드리지 않게 구분한다.
  int _generation = 0;

  @override
  FeedbackFlowState build() {
    // 로그아웃·세션 만료·탈퇴 뒤에 다음 계정으로 이전 흐름 상태가 새지 않게 비운다.
    ref.listen(authStatusControllerProvider, (previous, next) {
      if (next != AuthStatus.signedIn) {
        reset();
      }
    });
    return FeedbackFlowState.initial;
  }

  /// 이전 상태를 모두 비우고 [callSessionId] 통화의 흐름을 시작한다.
  void start(String callSessionId) {
    _generation += 1;
    state = FeedbackFlowState.initial.copyWith(callSessionId: callSessionId);
  }

  /// 통화의 피드백 상태를 불러온다. 실패해도 상태는 그대로라 같은 입력으로 다시 시도할 수 있다.
  /// AI 서버가 끝난 통화를 아직 보고하지 않아 `CALL_NOT_FEEDBACKABLE`이 오면 정책만큼 재시도하고,
  /// 끝내 받을 수 없으면 오류 표시 없이 [FeedbackStatusLoadResult.unavailable]을 돌려준다.
  Future<FeedbackStatusLoadResult> loadStatus() async {
    final callSessionId = state.callSessionId;
    if (state.isRequestInProgress || callSessionId == null) {
      return FeedbackStatusLoadResult.ignored;
    }
    final generation = _generation;
    state = state.copyWith(isRequestInProgress: true);
    try {
      final status = await _fetchStatusWithRetry(callSessionId, generation);
      if (status == null || generation != _generation) {
        return FeedbackStatusLoadResult.ignored;
      }
      state = state.copyWith(status: status);
      if (status.requiredFeedbackSubmitted) {
        // 홈이 아직 남아 있는 미제출 안내를 다시 읽도록 한다.
        _invalidateHomeSummary();
        return FeedbackStatusLoadResult.alreadySubmitted;
      }
      return FeedbackStatusLoadResult.ready;
    } catch (error) {
      if (_hasErrorCode(error, ErrorCode.callNotFeedbackable)) {
        return FeedbackStatusLoadResult.unavailable;
      }
      ref.read(errorHandlerProvider).handle(error);
      if (_isCallSessionNotFound(error)) {
        _invalidateHomeSummary();
        return FeedbackStatusLoadResult.unavailable;
      }
      return FeedbackStatusLoadResult.failed;
    } finally {
      _releaseRequest(generation);
    }
  }

  /// `CALL_NOT_FEEDBACKABLE`일 때만 정책의 간격·횟수대로 다시 조회한다.
  /// 대기 중 흐름이 바뀌면 `null`을 돌려주고, 횟수를 다 쓰면 마지막 오류를 그대로 던진다.
  Future<FeedbackStatus?> _fetchStatusWithRetry(
    String callSessionId,
    int generation,
  ) async {
    final policy = ref.read(feedbackStatusRetryPolicyProvider);
    for (var attempt = 1; ; attempt += 1) {
      try {
        return await ref
            .read(feedbackRepositoryProvider)
            .fetchStatus(callSessionId);
      } on Object catch (error) {
        final retryable =
            _hasErrorCode(error, ErrorCode.callNotFeedbackable) &&
            attempt < policy.maxAttempts;
        if (!retryable) {
          rethrow;
        }
      }
      await Future<void>.delayed(policy.interval);
      if (generation != _generation) {
        return null;
      }
    }
  }

  void setRating(int rating) {
    state = state.copyWith(
      requiredAnswers: state.requiredAnswers.withRating(rating),
    );
  }

  void setRevisitIntention(RevisitIntention intention) {
    state = state.copyWith(
      requiredAnswers: state.requiredAnswers.withRevisitIntention(intention),
    );
  }

  void setPreviousCallRecall(PreviousCallRecall recall) {
    state = state.copyWith(
      requiredAnswers: state.requiredAnswers.withPreviousCallRecall(recall),
    );
  }

  void toggleAwkwardMoment(AwkwardMoment moment) {
    state = state.copyWith(
      requiredAnswers: state.requiredAnswers.toggleAwkwardMoment(moment),
    );
  }

  /// 필수 피드백을 제출한다. 성공하면 홈 요약을 다시 불러오도록 무효화한다.
  Future<RequiredFeedbackSubmitResult> submitRequired() async {
    final callSessionId = state.callSessionId;
    final status = state.status;
    if (state.isRequestInProgress || callSessionId == null || status == null) {
      return RequiredFeedbackSubmitResult.ignored;
    }
    final submission = state.requiredAnswers.toSubmission(
      previousCallRecallRequired: status.previousCallRecallRequired,
    );
    if (submission == null) {
      return RequiredFeedbackSubmitResult.ignored;
    }
    final generation = _generation;
    state = state.copyWith(isRequestInProgress: true);
    try {
      final invited = await ref
          .read(feedbackRepositoryProvider)
          .submitRequired(callSessionId, submission);
      if (generation != _generation) {
        return RequiredFeedbackSubmitResult.ignored;
      }
      state = state.copyWith(
        requiredSubmitted: true,
        detailedFeedbackInvited: invited,
      );
      _invalidateHomeSummary();
      return invited
          ? RequiredFeedbackSubmitResult.submittedWithInvitation
          : RequiredFeedbackSubmitResult.submitted;
    } catch (error) {
      if (_isAlreadySubmitted(error)) {
        _invalidateHomeSummary();
        return RequiredFeedbackSubmitResult.alreadySubmitted;
      }
      ref.read(errorHandlerProvider).handle(error);
      return RequiredFeedbackSubmitResult.failed;
    } finally {
      _releaseRequest(generation);
    }
  }

  void setDetailedScore(DetailedFeedbackQuestion question, int score) {
    state = state.copyWith(
      detailedAnswers: state.detailedAnswers.withScore(question, score),
    );
  }

  void setDetailedReason(DetailedFeedbackQuestion question, String reason) {
    state = state.copyWith(
      detailedAnswers: state.detailedAnswers.withReason(question, reason),
    );
  }

  void setMemoryNotApplicable(bool notApplicable) {
    state = state.copyWith(
      detailedAnswers: state.detailedAnswers.withMemoryNotApplicable(
        notApplicable,
      ),
    );
  }

  void setFreeText(String text) {
    state = state.copyWith(
      detailedAnswers: state.detailedAnswers.withFreeText(text),
    );
  }

  void toggleStartReason(StartReason reason) {
    state = state.copyWith(
      detailedAnswers: state.detailedAnswers.toggleStartReason(reason),
    );
  }

  void setStartReasonOtherText(String text) {
    state = state.copyWith(
      detailedAnswers: state.detailedAnswers.withStartReasonOtherText(text),
    );
  }

  /// 상세 피드백을 제출한다. 상세 피드백 초대를 받지 않았으면 보내지 않는다.
  Future<DetailedFeedbackSubmitResult> submitDetailed() async {
    final callSessionId = state.callSessionId;
    if (state.isRequestInProgress ||
        callSessionId == null ||
        !state.requiredSubmitted ||
        !state.detailedFeedbackInvited) {
      return DetailedFeedbackSubmitResult.ignored;
    }
    final submission = state.detailedAnswers.toSubmission();
    if (submission == null) {
      return DetailedFeedbackSubmitResult.ignored;
    }
    final generation = _generation;
    state = state.copyWith(isRequestInProgress: true);
    try {
      await ref
          .read(feedbackRepositoryProvider)
          .submitDetailed(callSessionId, submission);
      if (generation != _generation) {
        return DetailedFeedbackSubmitResult.ignored;
      }
      state = state.copyWith(detailedSubmitted: true);
      return DetailedFeedbackSubmitResult.submitted;
    } catch (error) {
      if (_isAlreadySubmitted(error)) {
        return DetailedFeedbackSubmitResult.alreadySubmitted;
      }
      ref.read(errorHandlerProvider).handle(error);
      return DetailedFeedbackSubmitResult.failed;
    } finally {
      _releaseRequest(generation);
    }
  }

  void reset() {
    _generation += 1;
    state = FeedbackFlowState.initial;
  }

  /// 저장소 오류는 `DioException`이 `ApiException`을 감싼 모양이라 먼저 정규화한다.
  bool _isAlreadySubmitted(Object error) =>
      _hasErrorCode(error, ErrorCode.feedbackAlreadySubmitted);

  bool _isCallSessionNotFound(Object error) =>
      _hasErrorCode(error, ErrorCode.callSessionNotFound);

  bool _hasErrorCode(Object error, ErrorCode errorCode) {
    final exception = AppException.from(error);
    return exception is ApiException && exception.errorCode == errorCode;
  }

  /// 요청 중 표시를 내린다. 그 사이 흐름이 다시 시작되거나 비워졌으면 새 흐름의 표시를 건드리지 않는다.
  void _releaseRequest(int generation) {
    if (generation == _generation) {
      state = state.copyWith(isRequestInProgress: false);
    }
  }

  void _invalidateHomeSummary() {
    final member = ref.read(currentMemberControllerProvider);
    if (member != null) {
      ref.invalidate(homeSummaryProvider(member.memberId));
    }
  }
}
