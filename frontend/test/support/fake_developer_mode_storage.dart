import 'package:teeq/core/debug_console/developer_mode_storage.dart';

/// 메모리에 활성화 플래그를 보관하는 테스트용 저장소.
class FakeDeveloperModeStorage implements DeveloperModeStorage {
  FakeDeveloperModeStorage({this.storedEnabled = false, this.writeError});

  /// 현재 저장된 값.
  bool storedEnabled;

  /// 지정하면 [writeEnabled]가 이 오류를 던진다.
  final Object? writeError;

  int writeCount = 0;

  @override
  Future<bool> readEnabled() async => storedEnabled;

  @override
  Future<void> writeEnabled(bool enabled) async {
    writeCount++;
    final error = writeError;
    if (error != null) {
      throw error;
    }
    storedEnabled = enabled;
  }
}
