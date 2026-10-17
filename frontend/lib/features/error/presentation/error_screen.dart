import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_messages.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/router/error_page_arguments.dart';

/// 화면을 이어 갈 수 없는 오류를 알리는 화면.
/// 디자인 시안 확정 전 임시: 일러스트·아이콘 없이 문구와 버튼만 둔다.
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, this.arguments});

  /// 핫 리스타트·딥링크로 들어오면 null이다. 이때는 일반 문구와 홈 이동으로 처리한다.
  final ErrorPageArguments? arguments;

  @override
  Widget build(BuildContext context) {
    final message = arguments?.message ?? unknownErrorMessage;
    final retryLocation = arguments?.retryLocation ?? AppRoutes.home;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.horizontalMargin,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.paragraph16,
              ),
              const SizedBox(height: AppSpacing.space24),
              FilledButton(
                onPressed: () => context.go(retryLocation),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
