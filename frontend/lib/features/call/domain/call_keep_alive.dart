import 'package:teeq/core/text/korean_particle.dart';

/// 앱이 백그라운드로 가도 통화가 이어지도록 포그라운드 서비스(알림)를 유지하는 계약.
abstract interface class CallKeepAlive {
  Future<void> start({required String notificationBody});

  Future<void> stop();
}

/// 통화 중 알림 본문. 캐릭터 이름이 없으면 이름 없이 만든다.
String buildCallNotificationBody(String? characterName) {
  if (characterName == null || characterName.isEmpty) {
    return '통화 중이에요';
  }
  return '${withConjunctiveParticle(characterName)} 통화 중이에요';
}
