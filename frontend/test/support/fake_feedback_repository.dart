import 'dart:async';

import 'package:dio/dio.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/feedback_repository.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/required_feedback_submission.dart';

/// 실제 인터셉터와 같은 모양(`DioException`이 [ApiException]을 감쌈)의 서버 오류를 만든다.
DioException apiFailure(ErrorCode errorCode, {int httpStatus = 409}) =>
    DioException(
      requestOptions: RequestOptions(path: '/'),
      error: ApiException(errorCode: errorCode, httpStatus: httpStatus),
    );

/// 호출을 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 피드백 저장소.
class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository({
    this.status,
    this.statusError,
    this.submitRequiredError,
    this.detailedFeedbackInvited = false,
    this.submitDetailedError,
    this.gate,
  });

  final FeedbackStatus? status;

  /// 지정하면 [fetchStatus]가 이 오류를 던진다.
  final Object? statusError;

  /// 지정하면 [submitRequired]가 이 오류를 던진다.
  final Object? submitRequiredError;

  /// [submitRequired]가 돌려줄 상세 피드백 초대 여부.
  final bool detailedFeedbackInvited;

  /// 지정하면 [submitDetailed]가 이 오류를 던진다.
  final Object? submitDetailedError;

  /// 지정하면 모든 호출이 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용).
  final Completer<void>? gate;

  int fetchStatusCount = 0;
  final List<RequiredFeedbackSubmission> submitRequiredCalls = [];
  final List<DetailedFeedbackSubmission> submitDetailedCalls = [];

  @override
  Future<FeedbackStatus> fetchStatus(String callSessionId) async {
    fetchStatusCount += 1;
    await gate?.future;
    final failure = statusError;
    if (failure != null) {
      throw failure;
    }
    return status!;
  }

  @override
  Future<bool> submitRequired(
    String callSessionId,
    RequiredFeedbackSubmission submission,
  ) async {
    submitRequiredCalls.add(submission);
    await gate?.future;
    final failure = submitRequiredError;
    if (failure != null) {
      throw failure;
    }
    return detailedFeedbackInvited;
  }

  @override
  Future<void> submitDetailed(
    String callSessionId,
    DetailedFeedbackSubmission submission,
  ) async {
    submitDetailedCalls.add(submission);
    await gate?.future;
    final failure = submitDetailedError;
    if (failure != null) {
      throw failure;
    }
  }
}
