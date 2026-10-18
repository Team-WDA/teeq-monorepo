import 'package:flutter/material.dart';

/// 라우팅 구조를 확인하기 위한 자리표시 화면. 실제 가입 완료 화면은 인증 UI 이슈에서 교체한다.
class SignupCompletionScreen extends StatelessWidget {
  const SignupCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('가입 완료')));
  }
}
