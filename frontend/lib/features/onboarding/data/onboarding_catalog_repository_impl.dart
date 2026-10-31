import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/onboarding/data/dto/onboarding_catalog_response_dto.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog_repository.dart';
import 'package:teeq/features/onboarding/domain/onboarding_copy.dart';
import 'package:teeq/features/onboarding/domain/onboarding_option.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

part 'onboarding_catalog_repository_impl.g.dart';

/// [Dio]로 온보딩 질문 구조를 받아 [OnboardingCopy] 문구와 합치는 구현.
/// 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class OnboardingCatalogRepositoryImpl
    implements OnboardingCatalogRepository {
  OnboardingCatalogRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<OnboardingCatalog> fetchCatalog() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/onboarding/questions',
    );
    final dto = OnboardingCatalogResponseDto.fromJson(response.data!);
    return OnboardingCatalog([
      for (final question in dto.questions) _toQuestion(question),
    ]);
  }

  /// 사전에 없는 선택지는 빼고, 질문을 그릴 수 없으면 [UnexpectedException]을 던진다.
  OnboardingQuestion _toQuestion(OnboardingQuestionResponseDto question) {
    final copy = OnboardingCopy.questions[question.questionCode];
    if (copy == null) {
      throw UnexpectedException(
        StateError('문구가 없는 온보딩 질문 코드: ${question.questionCode}'),
      );
    }
    final options = [
      for (final optionCode in question.optionCodes)
        if (OnboardingCopy.optionLabels[optionCode] case final label?)
          OnboardingOption(code: optionCode, label: label),
    ];
    if (options.isEmpty || options.length < question.minSelections) {
      throw UnexpectedException(
        StateError('고를 수 있는 선택지가 부족한 온보딩 질문: ${question.questionCode}'),
      );
    }
    return OnboardingQuestion(
      code: question.questionCode,
      title: copy.title,
      description: copy.description,
      minSelections: question.minSelections,
      maxSelections: question.maxSelections,
      options: options,
    );
  }
}

@Riverpod(keepAlive: true)
OnboardingCatalogRepository onboardingCatalogRepository(Ref ref) =>
    OnboardingCatalogRepositoryImpl(ref.watch(dioProvider));
