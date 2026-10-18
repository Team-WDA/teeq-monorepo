import 'package:teeq/features/onboarding/domain/ai_character.dart';
import 'package:teeq/features/onboarding/domain/onboarding_selections.dart';

/// AI 캐릭터 생성과 이름 확정 API.
abstract interface class AiCharacterRepository {
  /// 선택한 답으로 캐릭터를 생성(재생성)한다. 이미 이름이 있으면 이름은 유지된다.
  Future<AiCharacter> generate({required OnboardingSelections selections});

  /// 생성된 캐릭터의 이름을 확정한다.
  Future<AiCharacter> confirmName({required String name});
}
