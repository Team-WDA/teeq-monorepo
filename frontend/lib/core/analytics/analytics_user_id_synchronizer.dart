import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/analytics/firebase_analytics_gateway.dart';
import 'package:teeq/core/auth/current_member_controller.dart';

part 'analytics_user_id_synchronizer.g.dart';

/// 회원 id가 바뀔 때만 GA4 user_id를 맞춘다. 로그아웃·탈퇴는 null로 해제한다.
@Riverpod(keepAlive: true)
void analyticsUserIdSynchronizer(Ref ref) {
  ref.listen(currentMemberControllerProvider, (previous, next) {
    if (previous?.memberId == next?.memberId) {
      return;
    }
    unawaited(ref.read(analyticsGatewayProvider).setUserId(next?.memberId));
  }, fireImmediately: true);
}
