import 'package:teeq/app.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/secure_developer_mode_storage.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/logging/global_log_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teeq/core/network/retry_policy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current.validate();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // 저장된 개발자 모드 플래그를 앱을 띄우기 전에 읽어, 시작 중 발생한 오류도 수집한다.
  final isDeveloperModeEnabled = await SecureDeveloperModeStorage(
    const FlutterSecureStorage(),
  ).readEnabled();
  final container = ProviderContainer(
    retry: providerRetry,
    overrides: [
      initialDeveloperModeEnabledProvider.overrideWithValue(
        isDeveloperModeEnabled,
      ),
    ],
  );
  installGlobalLogHooks(container.read(appLoggerProvider));
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
