import 'package:json_annotation/json_annotation.dart';

part 'onboarding_catalog_response_dto.g.dart';

/// 온보딩 질문 구조 응답(`OnboardingQuestionsResponse`).
@JsonSerializable(createToJson: false)
class OnboardingCatalogResponseDto {
  const OnboardingCatalogResponseDto({required this.questions});

  factory OnboardingCatalogResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OnboardingCatalogResponseDtoFromJson(json);

  final List<OnboardingQuestionResponseDto> questions;
}

/// 질문 하나의 구조(`OnboardingQuestionResponse`). 문구는 담지 않는다.
@JsonSerializable(createToJson: false)
class OnboardingQuestionResponseDto {
  const OnboardingQuestionResponseDto({
    required this.questionCode,
    required this.minSelections,
    required this.maxSelections,
    required this.optionCodes,
  });

  factory OnboardingQuestionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OnboardingQuestionResponseDtoFromJson(json);

  final String questionCode;
  final int minSelections;
  final int maxSelections;
  final List<String> optionCodes;
}
