import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/debug_console/secure_developer_mode_storage.dart';

part 'developer_mode_storage.g.dart';

/// 개발자 모드 활성화 플래그 저장소 계약. 테스트에서는 메모리 구현으로 바꾼다.
abstract interface class DeveloperModeStorage {
  /// 저장된 플래그를 돌려준다. 없거나 읽을 수 없으면 false.
  Future<bool> readEnabled();

  Future<void> writeEnabled(bool enabled);
}

@Riverpod(keepAlive: true)
DeveloperModeStorage developerModeStorage(Ref ref) =>
    SecureDeveloperModeStorage(const FlutterSecureStorage());
