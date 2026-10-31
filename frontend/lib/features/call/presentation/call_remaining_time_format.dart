/// 한도 칩에 보일 오늘 남은 통화 시간. 0초 이하는 "0분", 1~59초는 "1분 미만", 그 이상은 내림한 분이다.
String formatTodayRemainingMinutes(int remainingSeconds) {
  if (remainingSeconds <= 0) {
    return '0분';
  }
  if (remainingSeconds < Duration.secondsPerMinute) {
    return '1분 미만';
  }
  return '${remainingSeconds ~/ Duration.secondsPerMinute}분';
}
