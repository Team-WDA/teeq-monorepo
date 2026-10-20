import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/feedback/data/dto/feedback_status_response_dto.dart';
import 'package:teeq/features/feedback/data/dto/required_feedback_response_dto.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/feedback_repository.dart';
import 'package:teeq/features/feedback/domain/feedback_status.dart';
import 'package:teeq/features/feedback/domain/required_feedback_submission.dart';

part 'feedback_repository_impl.g.dart';

/// [Dio]로 피드백 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<FeedbackStatus> fetchStatus(String callSessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_callPath(callSessionId)}/feedback-status',
    );
    return FeedbackStatusResponseDto.fromJson(response.data!)
        .toFeedbackStatus();
  }

  @override
  Future<bool> submitRequired(
    String callSessionId,
    RequiredFeedbackSubmission submission,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_callPath(callSessionId)}/required-feedback',
      data: {
        'rating': submission.rating,
        'revisitIntention': submission.revisitIntention.code,
        if (submission.previousCallRecall != null)
          'previousCallRecall': submission.previousCallRecall!.code,
        'awkwardMoments': [
          for (final moment in submission.awkwardMoments) moment.code,
        ],
      },
    );
    return RequiredFeedbackResponseDto.fromJson(response.data!)
        .detailedFeedbackInvited;
  }

  @override
  Future<void> submitDetailed(
    String callSessionId,
    DetailedFeedbackSubmission submission,
  ) async {
    await _dio.post<void>(
      '${_callPath(callSessionId)}/detailed-feedback',
      // 문항 이름(`timing` 등)이 BE 필드 접두사(`timingScore`, `timingReason`)와 같다.
      data: {
        for (final question in DetailedFeedbackQuestion.values) ...{
          if (submission.scores[question] != null)
            '${question.name}Score': submission.scores[question],
          if (submission.reasons[question] != null)
            '${question.name}Reason': submission.reasons[question],
        },
        'memoryNotApplicable': submission.memoryNotApplicable,
        if (submission.freeText != null) 'freeText': submission.freeText,
        'startReasons': [
          for (final reason in submission.startReasons) reason.code,
        ],
        if (submission.startReasonOtherText != null)
          'startReasonOtherText': submission.startReasonOtherText,
      },
    );
  }

  String _callPath(String callSessionId) =>
      '/api/calls/${Uri.encodeComponent(callSessionId)}';
}

@Riverpod(keepAlive: true)
FeedbackRepository feedbackRepository(Ref ref) =>
    FeedbackRepositoryImpl(ref.watch(dioProvider));
