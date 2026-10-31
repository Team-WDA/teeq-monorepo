/// 통화 경과 시간을 `mm:ss`로 만든다. 60분 이상이면 분이 그대로 늘어난다.
String formatCallElapsed(Duration elapsed) {
  final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
