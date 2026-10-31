import 'dart:async';

import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/ai_character_repository.dart';
import 'package:teeq/features/onboarding/domain/onboarding_catalog.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

/// 호출을 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 저장소.
class FakeAiCharacterRepository implements AiCharacterRepository {
  FakeAiCharacterRepository({
    this.generateResult,
    this.generateError,
    this.confirmNameResult,
    this.confirmNameError,
    this.generateGate,
    this.confirmNameGate,
  });

  final AiCharacter? generateResult;

  /// 지정하면 [generate]가 이 오류를 던진다.
  final Object? generateError;
  final AiCharacter? confirmNameResult;

  /// 지정하면 [confirmName]이 이 오류를 던진다.
  final Object? confirmNameError;

  /// 지정하면 [generate]가 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용).
  final Completer<void>? generateGate;

  /// 지정하면 [confirmName]이 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용).
  final Completer<void>? confirmNameGate;

  final List<({OnboardingCatalog catalog, OnboardingSelections selections})>
  generateCalls = [];
  final List<String> confirmedNames = [];

  @override
  Future<AiCharacter> generate({
    required OnboardingCatalog catalog,
    required OnboardingSelections selections,
  }) async {
    generateCalls.add((catalog: catalog, selections: selections));
    await generateGate?.future;
    final error = generateError;
    if (error != null) {
      throw error;
    }
    return generateResult!;
  }

  @override
  Future<AiCharacter> confirmName({required String name}) async {
    confirmedNames.add(name);
    await confirmNameGate?.future;
    final error = confirmNameError;
    if (error != null) {
      throw error;
    }
    return confirmNameResult!;
  }
}
