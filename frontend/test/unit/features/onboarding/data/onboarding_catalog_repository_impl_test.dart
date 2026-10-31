import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/onboarding/data/onboarding_catalog_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog_repository.dart';

import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _questionsPath = '/api/onboarding/questions';

({OnboardingCatalogRepository repository, ScriptedHttpClientAdapter adapter})
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
    repository: container.read(onboardingCatalogRepositoryProvider),
    adapter: adapter,
  );
}

Map<String, Object?> _question(
  String questionCode,
  List<String> optionCodes, {
  int minSelections = 1,
  int maxSelections = 1,
}) => {
  'questionCode': questionCode,
  'minSelections': minSelections,
  'maxSelections': maxSelections,
  'optionCodes': optionCodes,
};

void _scriptQuestions(
  ScriptedHttpClientAdapter adapter,
  List<Map<String, Object?>> questions,
) {
  adapter.on(_questionsPath, [
    ScriptedReply.json(200, {'questions': questions}),
  ]);
}

void main() {
  test('fetch_알려진_코드는_문구와_합쳐_서버_순서로_반환한다', () async {
    final (:repository, :adapter) = _setUp();
    _scriptQuestions(adapter, [
      _question('PERSONALITY', [
        'PERSONALITY_CALM_WARM',
        'PERSONALITY_MOOD_MAKER',
      ]),
      _question('RELATIONSHIP', ['RELATIONSHIP_CLOSE_FRIEND']),
    ]);

    final catalog = await repository.fetchCatalog();

    expect(adapter.requestsTo(_questionsPath).single.method, 'GET');
    expect(catalog.questions.map((question) => question.code), [
      'PERSONALITY',
      'RELATIONSHIP',
    ]);
    final personality = catalog.questions.first;
    expect(personality.title, '너는 어떤\n성격이 좋아?');
    expect(personality.description, '마음에 드는 성격을 골라줘.');
    expect(personality.options.map((option) => option.code), [
      'PERSONALITY_CALM_WARM',
      'PERSONALITY_MOOD_MAKER',
    ]);
    expect(personality.options.map((option) => option.label), [
      '차분하고 따뜻한 다정다감형',
      '밝고 에너지 넘치는 분위기 메이커 스타일',
    ]);
  });

  test('fetch_모르는_선택지_코드는_제외한다', () async {
    final (:repository, :adapter) = _setUp();
    _scriptQuestions(adapter, [
      _question('RELATIONSHIP', [
        'RELATIONSHIP_CLOSE_FRIEND',
        'RELATIONSHIP_UNKNOWN_NEW',
        'RELATIONSHIP_LIFE_MENTOR',
      ]),
    ]);

    final catalog = await repository.fetchCatalog();

    expect(catalog.questions.single.options.map((option) => option.code), [
      'RELATIONSHIP_CLOSE_FRIEND',
      'RELATIONSHIP_LIFE_MENTOR',
    ]);
  });

  test('fetch_모르는_질문_코드면_UnexpectedException', () async {
    final (:repository, :adapter) = _setUp();
    _scriptQuestions(adapter, [
      _question('RELATIONSHIP', ['RELATIONSHIP_CLOSE_FRIEND']),
      _question('UNKNOWN_QUESTION', ['UNKNOWN_QUESTION_OPTION']),
    ]);

    await expectLater(
      repository.fetchCatalog(),
      throwsA(isA<UnexpectedException>()),
    );
  });

  test('fetch_질문의_선택지가_모두_모르는_코드면_UnexpectedException', () async {
    final (:repository, :adapter) = _setUp();
    _scriptQuestions(adapter, [
      _question('RELATIONSHIP', [
        'RELATIONSHIP_UNKNOWN_FIRST',
        'RELATIONSHIP_UNKNOWN_SECOND',
      ]),
    ]);

    await expectLater(
      repository.fetchCatalog(),
      throwsA(isA<UnexpectedException>()),
    );
  });

  test('fetch_남은_선택지가_최소_선택_수보다_적으면_UnexpectedException', () async {
    final (:repository, :adapter) = _setUp();
    _scriptQuestions(adapter, [
      _question(
        'AVOID_BEHAVIOR',
        ['AVOID_BEHAVIOR_INTERRUPTING', 'AVOID_BEHAVIOR_UNKNOWN_NEW'],
        minSelections: 2,
        maxSelections: 5,
      ),
    ]);

    await expectLater(
      repository.fetchCatalog(),
      throwsA(isA<UnexpectedException>()),
    );
  });

  test('fetch_서버_구조의_선택_수를_그대로_쓴다', () async {
    final (:repository, :adapter) = _setUp();
    _scriptQuestions(adapter, [
      _question('RELATIONSHIP', ['RELATIONSHIP_CLOSE_FRIEND']),
      _question('AVOID_BEHAVIOR', [
        'AVOID_BEHAVIOR_RAPID_QUESTIONS',
        'AVOID_BEHAVIOR_UNASKED_ADVICE',
        'AVOID_BEHAVIOR_EXCESSIVE_POSITIVITY',
        'AVOID_BEHAVIOR_REPEATED_RESPONSES',
        'AVOID_BEHAVIOR_INTERRUPTING',
      ], maxSelections: 5),
    ]);

    final catalog = await repository.fetchCatalog();

    final relationship = catalog.questions.first;
    expect(relationship.minSelections, 1);
    expect(relationship.maxSelections, 1);
    expect(relationship.isMultipleChoice, isFalse);
    final avoidBehavior = catalog.questions.last;
    expect(avoidBehavior.minSelections, 1);
    expect(avoidBehavior.maxSelections, 5);
    expect(avoidBehavior.isMultipleChoice, isTrue);
  });
}
