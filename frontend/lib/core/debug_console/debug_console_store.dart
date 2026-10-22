import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/debug_console/bounded_list.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/network_log_entry.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';

part 'debug_console_store.g.dart';

/// 디버그 콘솔이 보여 주는 목록. 모두 오래된 것에서 최신 순이다.
final class DebugConsoleState {
  const DebugConsoleState({
    this.networkEntries = const [],
    this.applicationLogs = const [],
    this.errorLogs = const [],
  });

  final List<NetworkLogEntry> networkEntries;
  final List<AppLogEntry> applicationLogs;

  /// 에러 레벨 로그. 디버그 로그가 많이 쌓여도 밀려나지 않게 따로 보관한다.
  final List<AppLogEntry> errorLogs;

  DebugConsoleState copyWith({
    List<NetworkLogEntry>? networkEntries,
    List<AppLogEntry>? applicationLogs,
    List<AppLogEntry>? errorLogs,
  }) {
    return DebugConsoleState(
      networkEntries: networkEntries ?? this.networkEntries,
      applicationLogs: applicationLogs ?? this.applicationLogs,
      errorLogs: errorLogs ?? this.errorLogs,
    );
  }
}

/// 네트워크 기록과 앱 로그를 메모리에 보관한다. 개발자 모드가 꺼져 있으면 기록하지 않고,
/// 꺼지는 순간 모두 비운다.
@Riverpod(keepAlive: true)
class DebugConsoleStore extends _$DebugConsoleStore {
  int _networkEntrySequence = 0;

  @override
  DebugConsoleState build() {
    ref.listen(developerModeControllerProvider, (previous, isEnabled) {
      if (!isEnabled) {
        state = const DebugConsoleState();
      }
    });
    return const DebugConsoleState();
  }

  bool get isCollecting => ref.read(developerModeControllerProvider);

  /// 인터셉터가 요청마다 붙일 기록 번호. dio와 plainDio가 같은 저장소를 쓰므로 여기서 발급한다.
  String nextNetworkEntryId() => '${++_networkEntrySequence}';

  void recordLog(AppLogEntry entry) {
    if (!isCollecting) {
      return;
    }
    state = state.copyWith(
      applicationLogs: appendBounded(state.applicationLogs, entry),
      errorLogs: entry.level == AppLogLevel.error
          ? appendBounded(state.errorLogs, entry)
          : state.errorLogs,
    );
  }

  void recordNetworkStart(NetworkLogEntry entry) {
    if (!isCollecting) {
      return;
    }
    state = state.copyWith(
      networkEntries: appendBounded(state.networkEntries, entry),
    );
  }

  /// 같은 `id`의 기록을 완료본으로 바꾼다. 이미 밀려났거나 없으면 무시한다.
  void recordNetworkCompletion(NetworkLogEntry completed) {
    if (!isCollecting) {
      return;
    }
    final index = state.networkEntries.indexWhere(
      (entry) => entry.id == completed.id,
    );
    if (index < 0) {
      return;
    }
    final replaced = [...state.networkEntries]..[index] = completed;
    state = state.copyWith(networkEntries: List.unmodifiable(replaced));
  }

  void clearNetworkEntries() {
    state = state.copyWith(networkEntries: const []);
  }

  void clearApplicationLogs() {
    state = state.copyWith(applicationLogs: const []);
  }

  void clearErrorLogs() {
    state = state.copyWith(errorLogs: const []);
  }

  void clearAll() {
    state = const DebugConsoleState();
  }
}
