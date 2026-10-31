/// 피드백 흐름 경로(`/calls/<id>/feedback...`)면 그 통화 세션 id를, 아니면 null을 돌려준다.
String? callSessionIdFromFeedbackPath(String path) {
  final segments = Uri.parse(path).pathSegments;
  final isFeedbackFlowPath =
      segments.length >= 3 &&
      segments[0] == 'calls' &&
      segments[2] == 'feedback';
  if (!isFeedbackFlowPath) {
    return null;
  }
  // pathSegments는 이미 디코딩된 값이다.
  return segments[1];
}
