import 'package:flutter/material.dart';
import 'package:teeq/core/design/app_colors.dart';

/// 로그인 상태를 확인하는 동안 보여 주는 화면.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 로고 자리는 비워 둔다. 로고는 디자이너에게 에셋을 받은 뒤 넣는다.
    return const Scaffold(backgroundColor: AppColors.background);
  }
}
