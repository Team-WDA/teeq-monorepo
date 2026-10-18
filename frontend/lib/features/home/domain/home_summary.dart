import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_summary.freezed.dart';

/// 홈 화면에 보여 줄 캐릭터 이름, 성향 태그, 오늘의 한마디. [greeting]은 줄바꿈(`\n`)을 포함할 수 있다.
@freezed
abstract class HomeSummary with _$HomeSummary {
  const factory HomeSummary({
    required String characterName,
    required List<String> personalityTags,
    required String greeting,
  }) = _HomeSummary;
}
