import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/analytics/firebase_analytics_gateway.dart';
import 'package:teeq/core/auth/current_member_controller.dart';

part 'analytics_user_id_synchronizer.g.dart';

/// 회원 id가 바뀔 때 GA4 user_id를 맞춘다. 로그아웃·탈퇴는 null로 해제한다.
/// 앱 시작 때는 회원이 없어도 한 번 맞춘다. user_id가 기기에 남아 이전 계정으로 기록되지 않게 하려는 것이다.
@Riverpod(keepAlive: true)
void analyticsUserIdSynchronizer(Ref ref) {
  ref.listen(currentMemberControllerProvider, (previous, next) {
    if (previous != null && previous.memberId == next?.memberId) {
      return;
    }
    unawaited(ref.read(analyticsGatewayProvider).setUserId(next?.memberId));
  }, fireImmediately: true);
}
