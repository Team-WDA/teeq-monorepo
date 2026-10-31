import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

part 'current_character_type_provider.g.dart';

/// 로그인한 회원의 캐릭터 외형. 회원이 없거나 홈 요약이 로딩 중이거나 실패하면 [CharacterType.character1]이다.
@riverpod
CharacterType currentCharacterType(Ref ref) {
  final memberId = ref.watch(
    currentMemberControllerProvider.select((member) => member?.memberId),
  );
  if (memberId == null) {
    return CharacterType.character1;
  }
  return ref.watch(homeSummaryProvider(memberId)).value?.characterType ??
      CharacterType.character1;
}
