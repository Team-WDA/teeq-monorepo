import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/ui/toast/app_toast.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';

/// 앱 전체 위에 현재 토스트를 겹쳐 보여 준다. `MaterialApp.builder`에서 감싼다.
/// 디자인 시안 확정 전 임시: 모션 없이 즉시 나타나고 사라진다.
class AppToastHost extends ConsumerWidget {
  const AppToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(toastControllerProvider);
    return Stack(
      children: [
        child,
        if (message != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppLayout.gutter,
                        0,
                        AppLayout.gutter,
                        AppSpacing.space16,
                      ),
                      child: AppToast(message: message),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
