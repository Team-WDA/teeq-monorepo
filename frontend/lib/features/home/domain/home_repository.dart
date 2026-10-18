import 'package:teeq/features/home/domain/home_summary.dart';

/// 홈 화면 API.
abstract interface class HomeRepository {
  /// 홈 화면에 필요한 요약을 조회한다.
  Future<HomeSummary> fetchHome();
}
