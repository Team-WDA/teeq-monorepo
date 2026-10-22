/// 디버그 콘솔 패널의 탭.
enum DebugConsoleTab {
  network('네트워크'),
  applicationLog('로그'),
  error('에러'),
  applicationInformation('앱 정보');

  const DebugConsoleTab(this.label);

  final String label;
}
