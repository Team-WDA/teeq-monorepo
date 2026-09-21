import 'package:flutter/material.dart';

/// 라우팅 구조를 확인하기 위한 자리표시 화면. 실제 홈 화면은 기능 개발 시 교체한다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('ai-friend')));
  }
}
