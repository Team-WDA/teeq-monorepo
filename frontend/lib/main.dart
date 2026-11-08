import 'package:firebase_core/firebase_core.dart';
import 'package:teeq/app.dart';
import 'package:teeq/core/analytics/firebase_analytics_gateway.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/debug_console/developer_mode_controller.dart';
import 'package:teeq/core/debug_console/secure_developer_mode_storage.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/logging/global_log_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:teeq/core/network/retry_policy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.current.validate();
  // 네이티브 설정 파일(google-services.json, GoogleService-Info.plist)로 초기화한다.
  await Firebase.initializeApp();
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
  // debug 빌드의 모든 이벤트에 debug_mode를 붙여 GA4 개발자 트래픽 필터가 제외하게 한다. release 빌드는 아무것도 하지 않는다.
  if (kDebugMode) {
    await container.read(analyticsGatewayProvider).setDefaultEventParameters({
      'debug_mode': true,
    });
  }
  installGlobalLogHooks(container.read(appLoggerProvider));
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
