import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/ai_character_repository.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

import '../../../../support/fake_onboarding_catalog_repository.dart';
import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _characterJson = {
  'name': null,
  'characterType': 'CHARACTER_3',
  'personalityTags': ['다정한', '차분한', '든든한'],
};

({AiCharacterRepository repository, ScriptedHttpClientAdapter adapter})
_setUp() {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      appConfigProvider.overrideWithValue(
        const AppConfig(apiBaseUrl: 'https://api.example.test'),
      ),
    ],
  );
  addTearDown(container.dispose);
  final adapter = ScriptedHttpClientAdapter();
  container.read(dioProvider).httpClientAdapter = adapter;
  return (
    repository: container.read(aiCharacterRepositoryProvider),
    adapter: adapter,
  );
}

/// 각 질문의 첫 선택지를 고르고, 마지막 질문은 다섯 번째를 먼저 고른 뒤 첫 번째를 더한다.
OnboardingSelections _allQuestionsAnswered() {
  final avoidBehavior = testOnboardingQuestion('AVOID_BEHAVIOR');
  var selections = const OnboardingSelections.empty().toggle(
    avoidBehavior,
    testOnboardingOption('AVOID_BEHAVIOR_INTERRUPTING'),
  );
  for (final question in testOnboardingCatalog.questions) {
    selections = selections.toggle(question, question.options.first);
  }
  return selections;
}

void main() {
  test('generate_sendsAnswersInCatalogAndOptionOrder', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/ai-characters/me', [
      ScriptedReply.json(201, _characterJson),
    ]);

    final character = await repository.generate(
      catalog: testOnboardingCatalog,
      selections: _allQuestionsAnswered(),
    );

    final request = adapter.requestsTo('/api/ai-characters/me').single;
    expect(request.method, 'PUT');
    expect(request.data, {
      'onboardingAnswers': [
        {
          'questionCode': 'RELATIONSHIP',
          'optionCodes': ['RELATIONSHIP_CLOSE_FRIEND'],
        },
        {
          'questionCode': 'PERSONALITY',
          'optionCodes': ['PERSONALITY_MOOD_MAKER'],
        },
        {
          'questionCode': 'SPEECH_STYLE',
          'optionCodes': ['SPEECH_STYLE_CLOSE_FRIEND_CASUAL'],
        },
        {
          'questionCode': 'VOICE_TONE',
          'optionCodes': ['VOICE_TONE_HIGH_BRIGHT'],
        },
        {
          'questionCode': 'ADVICE_STYLE',
          'optionCodes': ['ADVICE_STYLE_EMPATHY_ONLY'],
        },
        {
          'questionCode': 'CONVERSATION_LEAD',
          'optionCodes': ['CONVERSATION_LEAD_LISTENER'],
        },
        {
          'questionCode': 'AVOID_BEHAVIOR',
          'optionCodes': [
            'AVOID_BEHAVIOR_RAPID_QUESTIONS',
            'AVOID_BEHAVIOR_INTERRUPTING',
          ],
        },
      ],
    });
    expect(
      character,
      const AiCharacter(
        name: null,
        characterType: CharacterType.character3,
        personalityTags: ['다정한', '차분한', '든든한'],
      ),
    );
  });

  test('generate_followsGivenCatalogQuestionOrder', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/ai-characters/me', [
      ScriptedReply.json(201, _characterJson),
    ]);
    final reversedCatalog = OnboardingCatalog(
      testOnboardingCatalog.questions.reversed.toList(),
    );

    await repository.generate(
      catalog: reversedCatalog,
      selections: _allQuestionsAnswered(),
    );

    final request = adapter.requestsTo('/api/ai-characters/me').single;
    final answers =
        (request.data as Map<String, dynamic>)['onboardingAnswers']
            as List<Object?>;
    expect(
      answers.map((answer) => (answer! as Map)['questionCode']).toList(),
      reversedCatalog.questions.map((question) => question.code).toList(),
    );
  });

  test('generate_existingNamedCharacter_returnsName', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/ai-characters/me', [
      ScriptedReply.json(200, {..._characterJson, 'name': '티티'}),
    ]);

    final character = await repository.generate(
      catalog: testOnboardingCatalog,
      selections: _allQuestionsAnswered(),
    );

    expect(character.name, '티티');
  });

  test('confirmName_sendsNameOnly', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/ai-characters/me/name', [
      ScriptedReply.json(200, {..._characterJson, 'name': '티티'}),
    ]);

    final character = await repository.confirmName(name: '티티');

    final request = adapter.requestsTo('/api/ai-characters/me/name').single;
    expect(request.method, 'PATCH');
    expect(request.data, {'name': '티티'});
    expect(character.name, '티티');
  });

  test('generate_propagatesFailure', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/ai-characters/me', [
      ScriptedReply.json(502, {
        'errorCode': 'AI_SERVER_UNAVAILABLE',
        'errorMessage': 'AI 서버 오류',
      }),
    ]);

    await expectLater(
      repository.generate(
        catalog: testOnboardingCatalog,
        selections: _allQuestionsAnswered(),
      ),
      throwsA(
        isA<DioException>().having(
          (exception) => exception.error,
          'error',
          isA<ApiException>(),
        ),
      ),
    );
  });
}
