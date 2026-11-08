import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/analytics/firebase_analytics_gateway.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/navigation/main_bottom_tab_bar.dart';

/// 홈·마이 탭의 공통 틀. 본문은 상태 표시줄 아래에 두고 하단 탭 바는 고정한다.
class MainTabShellScreen extends ConsumerStatefulWidget {
  const MainTabShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainTabShellScreen> createState() => _MainTabShellScreenState();
}

class _MainTabShellScreenState extends ConsumerState<MainTabShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _logCurrentTabScreenView();
    });
  }

  @override
  void didUpdateWidget(MainTabShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _logCurrentTabScreenView();
    }
  }

  // 탭 화면은 루트 observer가 기록하지 않으므로 탭 전환을 직접 기록한다.
  void _logCurrentTabScreenView() {
    unawaited(
      ref
          .read(analyticsGatewayProvider)
          .logScreenView(_tabScreenName(widget.navigationShell.currentIndex)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: widget.navigationShell),
      bottomNavigationBar: MainBottomTabBar(
        selectedIndex: widget.navigationShell.currentIndex,
        // 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
        onTabSelected: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}

String _tabScreenName(int tabIndex) => switch (tabIndex) {
  0 => AppRoutes.home,
  1 => AppRoutes.myPage,
  _ => throw ArgumentError.value(tabIndex, 'tabIndex', '알 수 없는 탭 인덱스'),
};
