import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/onboarding/data/dto/ai_character_response_dto.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/ai_character_repository.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

part 'ai_character_repository_impl.g.dart';

/// [Dio]로 AI 캐릭터 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class AiCharacterRepositoryImpl implements AiCharacterRepository {
  AiCharacterRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<AiCharacter> generate({
    required OnboardingSelections selections,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/ai-characters/me',
      data: {
        'onboardingAnswers': [
          for (final question in OnboardingQuestion.values)
            {
              'questionCode': question.code,
              'optionCodes': [
                for (final option in question.options)
                  if (selections.selectedFor(question).contains(option))
                    option.code,
              ],
            },
        ],
      },
    );
    return AiCharacterResponseDto.fromJson(response.data!).toAiCharacter();
  }

  @override
  Future<AiCharacter> confirmName({required String name}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/ai-characters/me/name',
      data: {'name': name},
    );
    return AiCharacterResponseDto.fromJson(response.data!).toAiCharacter();
  }
}

@Riverpod(keepAlive: true)
AiCharacterRepository aiCharacterRepository(Ref ref) =>
    AiCharacterRepositoryImpl(ref.watch(dioProvider));
