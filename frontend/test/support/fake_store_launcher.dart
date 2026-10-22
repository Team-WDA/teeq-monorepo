import 'dart:async';

import 'package:teeq/features/app_update/domain/store_launcher.dart';

/// 열기 요청한 주소를 기록하고 결과를 정하는 가짜 스토어 실행기.
/// [gate]가 있으면 그 Future가 끝날 때까지 `open`이 완료되지 않는다.
class FakeStoreLauncher implements StoreLauncher {
  FakeStoreLauncher({this.result = true, this.error, this.gate});

  final bool result;
  final Object? error;
  final Completer<void>? gate;

  /// `open`에 넘어온 주소들.
  final List<String> openedUrls = [];

  @override
  Future<bool> open(String storeUrl) async {
    openedUrls.add(storeUrl);
    await gate?.future;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return result;
  }
}
