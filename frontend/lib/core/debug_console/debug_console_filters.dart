import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

/// 네트워크 탭의 성공/실패 필터.
enum NetworkLogStatusFilter { all, success, failure }

/// URL 검색어(대소문자 무시, 빈 검색어는 전체)와 성공/실패 필터를 함께 적용한다.
/// 응답을 기다리는 호출은 [NetworkLogStatusFilter.all]에서만 보인다.
List<NetworkLogEntry> filterNetworkEntries(
  List<NetworkLogEntry> entries, {
  required String urlQuery,
  required NetworkLogStatusFilter statusFilter,
}) {
  final query = urlQuery.toLowerCase();
  return entries.where((entry) {
    final matchesUrl = entry.url.toLowerCase().contains(query);
    final matchesStatus = switch (statusFilter) {
      NetworkLogStatusFilter.all => true,
      NetworkLogStatusFilter.success =>
        entry.outcome == NetworkLogOutcome.success,
      NetworkLogStatusFilter.failure =>
        entry.outcome == NetworkLogOutcome.failure,
    };
    return matchesUrl && matchesStatus;
  }).toList();
}

/// [visibleLevels]에 든 레벨의 로그만 남긴다.
List<AppLogEntry> filterLogsByLevel(
  List<AppLogEntry> entries,
  Set<AppLogLevel> visibleLevels,
) {
  return entries.where((entry) => visibleLevels.contains(entry.level)).toList();
}
