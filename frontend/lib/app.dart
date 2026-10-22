import 'package:teeq/core/debug_console/presentation/debug_console_host.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/router/app_router.dart';
import 'package:teeq/core/ui/toast/app_toast_host.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'TeeQ',
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: AppLayout.maxTextScaleFactor,
        // 토스트가 콘솔 패널 위에도 보이도록 콘솔을 안쪽에 둔다.
        child: AppToastHost(child: DebugConsoleHost(child: child!)),
      ),
    );
  }
}
