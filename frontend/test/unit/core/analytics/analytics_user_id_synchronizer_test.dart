import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/analytics/analytics_user_id_synchronizer.dart';
import 'package:teeq/core/analytics/firebase_analytics_gateway.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';

import '../../../support/fake_analytics_gateway.dart';
import '../../../support/fake_current_member_controller.dart';

Member _member(String memberId, {String nickname = '닉네임'}) => Member(
  memberId: memberId,
  nickname: nickname,
  hasAiCharacter: true,
  loginType: LoginType.google,
);

ProviderContainer _createContainer(
  FakeAnalyticsGateway gateway,
  Member? initialMember,
) {
  final container = ProviderContainer(
    overrides: [
      analyticsGatewayProvider.overrideWithValue(gateway),
      currentMemberControllerProvider.overrideWith(
        () => FakeCurrentMemberController(initialMember),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('세션 복원으로 처음부터 회원이 있으면 곧바로 user_id를 설정한다', () {
    final gateway = FakeAnalyticsGateway();
    final container = _createContainer(gateway, _member('member-a'));

    container.read(analyticsUserIdSynchronizerProvider);

    expect(gateway.userIdCalls, ['member-a']);
  });

  test('로그아웃하면 user_id를 null로 해제하고 다른 회원으로 로그인하면 새 id를 설정한다', () {
    final gateway = FakeAnalyticsGateway();
    final container = _createContainer(gateway, _member('member-a'));
    container.read(analyticsUserIdSynchronizerProvider);

    container.read(currentMemberControllerProvider.notifier).clear();
    expect(gateway.userIdCalls, ['member-a', null]);

    container
        .read(currentMemberControllerProvider.notifier)
        .update(_member('member-b'));
    expect(gateway.userIdCalls, ['member-a', null, 'member-b']);
  });

  test('같은 회원의 닉네임만 바뀌면 user_id를 다시 설정하지 않는다', () {
    final gateway = FakeAnalyticsGateway();
    final container = _createContainer(gateway, _member('member-a'));
    container.read(analyticsUserIdSynchronizerProvider);

    container
        .read(currentMemberControllerProvider.notifier)
        .update(_member('member-a', nickname: '바뀐 닉네임'));

    expect(gateway.userIdCalls, ['member-a']);
  });

  test('회원이 없는 채로 시작해도 이전 user_id가 남지 않도록 null로 해제한다', () {
    final gateway = FakeAnalyticsGateway();
    final container = _createContainer(gateway, null);

    container.read(analyticsUserIdSynchronizerProvider);

    expect(gateway.userIdCalls, [null]);
  });
}
