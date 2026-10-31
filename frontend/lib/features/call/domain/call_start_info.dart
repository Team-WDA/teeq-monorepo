/// 통화 시작 API가 내려준 LiveKit 접속 정보.
final class CallStartInfo {
  const CallStartInfo({
    required this.callSessionId,
    required this.maxDurationSeconds,
    required this.serverUrl,
    required this.accessToken,
  });

  final String callSessionId;
  final int maxDurationSeconds;
  final String serverUrl;
  final String accessToken;
}
