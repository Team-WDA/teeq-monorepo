import 'dart:async';

import 'package:teeq/features/home/domain/home_repository.dart';
import 'package:teeq/features/home/domain/home_summary.dart';

/// 호출 횟수를 기록하고 미리 정한 결과 또는 오류를 돌려주는 테스트용 홈 저장소.
class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({
    this.summary,
    this.error,
    this.errorAfterFirstFetch,
    this.gate,
  });

  final HomeSummary? summary;

  /// 지정하면 [fetchHome]이 이 오류를 던진다.
  final Object? error;

  /// 지정하면 첫 호출은 성공하고 이후 호출부터 이 오류를 던진다(다시 불러오기 실패 재현용).
  final Object? errorAfterFirstFetch;

  /// 지정하면 [fetchHome]이 이 게이트가 완료될 때까지 기다린다(응답 지연 재현용). 테스트 중간에 바꿀 수 있다.
  Completer<void>? gate;

  int fetchCount = 0;

  @override
  Future<HomeSummary> fetchHome() async {
    fetchCount += 1;
    await gate?.future;
    final failure = error ?? (fetchCount > 1 ? errorAfterFirstFetch : null);
    if (failure != null) {
      throw failure;
    }
    return summary!;
  }
}
