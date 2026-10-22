import 'package:teeq/features/bug_report/domain/bug_report_environment.dart';

/// 제보에 실을 앱·기기 환경 정보를 읽는다.
abstract interface class BugReportEnvironmentReader {
  Future<BugReportEnvironment> read();
}
