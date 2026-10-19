import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/ui/navigation/main_bottom_tab_bar.dart';

/// 홈·마이 탭의 공통 틀. 본문은 상태 표시줄 아래에 두고 하단 탭 바는 고정한다.
class MainTabShellScreen extends StatelessWidget {
  const MainTabShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: MainBottomTabBar(
        selectedIndex: navigationShell.currentIndex,
        // 이미 선택된 탭을 다시 누르면 그 탭의 첫 화면으로 돌아간다.
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
