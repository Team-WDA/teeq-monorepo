/// 제보 출처. [wireValue]는 서버 요청의 `source` 값이다.
enum BugReportSource {
  user('USER'),
  developerConsole('DEVELOPER_CONSOLE');

  const BugReportSource(this.wireValue);

  final String wireValue;
}
