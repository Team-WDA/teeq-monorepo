import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:teeq/features/feedback/domain/pending_feedback.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

part 'home_summary.freezed.dart';

/// 홈 화면에 보여 줄 캐릭터 이름, 외형([characterType])과 표정([characterMood]), 성향 태그, 오늘의 한마디. [greeting]은 줄바꿈(`\n`)을 포함할 수 있다.
/// [pendingFeedback]은 필수 피드백을 아직 제출하지 않은 통화이며 없으면 null이다.
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    required String characterName,
    required CharacterType characterType,
    required CharacterMood characterMood,
    required List<String> personalityTags,
    required String greeting,
    PendingFeedback? pendingFeedback,
  }) = _HomeSummary;
}
