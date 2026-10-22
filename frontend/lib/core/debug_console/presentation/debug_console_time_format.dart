/// 콘솔 목록에 보여 줄 시각. 기기의 현지 시간으로 `HH:mm:ss.SSS` 형식이다.
String formatConsoleTime(DateTime moment) {
  final local = moment.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final milliseconds = local.millisecond.toString().padLeft(3, '0');
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)}:'
      '${twoDigits(local.second)}.$milliseconds';
}
