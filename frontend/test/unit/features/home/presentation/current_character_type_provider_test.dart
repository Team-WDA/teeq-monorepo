import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/character_mood.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/current_character_type_provider.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/onboarding/domain/character_type.dart';

import '../../../../support/fake_current_member_controller.dart';
import '../../../../support/fake_home_repository.dart';

const _member = Member(
  memberId: 'member-1',
  nickname: '닉네임',
  hasAiCharacter: true,
  loginType: LoginType.google,
);

const _summary = HomeSummary(
  characterName: '티큐',
  characterType: CharacterType.character4,
  characterMood: CharacterMood.welcome,
  personalityTags: ['다정한'],
  greeting: '안녕',
);

ProviderContainer _newContainer({
  Member? member,
  required FakeHomeRepository repository,
}) {
  final container = ProviderContainer(
    overrides: [
      currentMemberControllerProvider.overrideWith(
        () => FakeCurrentMemberController(member),
      ),
      homeRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('currentCharacterType_withoutMember_isCharacter1', () {
    final container = _newContainer(
      repository: FakeHomeRepository(summary: _summary),
    );

    expect(
      container.read(currentCharacterTypeProvider),
      CharacterType.character1,
    );
  });

  test('currentCharacterType_withSummary_followsSummary', () async {
    final container = _newContainer(
      member: _member,
      repository: FakeHomeRepository(summary: _summary),
    );
    container.listen(currentCharacterTypeProvider, (_, _) {});
    await container.read(homeSummaryProvider(_member.memberId).future);

    expect(
      container.read(currentCharacterTypeProvider),
      CharacterType.character4,
    );
  });

  test('currentCharacterType_whileLoading_isCharacter1', () {
    final container = _newContainer(
      member: _member,
      repository: FakeHomeRepository(
        summary: _summary,
        gate: Completer<void>(),
      ),
    );

    expect(
      container.read(currentCharacterTypeProvider),
      CharacterType.character1,
    );
  });

  test('currentCharacterType_onError_isCharacter1', () async {
    final container = _newContainer(
      member: _member,
      repository: FakeHomeRepository(error: StateError('실패')),
    );
    container.listen(currentCharacterTypeProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(currentCharacterTypeProvider),
      CharacterType.character1,
    );
  });
}
