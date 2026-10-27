import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/features/app_update/data/url_store_launcher.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';
import 'package:teeq/features/app_update/presentation/update_required_content.dart';

/// 최소버전 미달일 때 뒤로 갈 수 없이 스토어로 안내하는 화면.
class UpdateRequiredScreen extends ConsumerStatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  ConsumerState<UpdateRequiredScreen> createState() =>
      _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends ConsumerState<UpdateRequiredScreen> {
  /// 스토어를 여는 중이면 true. 처리 중 재진입을 막는다.
  bool _isOpeningStore = false;

  Future<void> _openStore(String storeUrl) async {
    if (_isOpeningStore) {
      return;
    }
    setState(() => _isOpeningStore = true);
    try {
      final isOpened = await ref.read(storeLauncherProvider).open(storeUrl);
      if (!isOpened && mounted) {
        ref
            .read(errorHandlerProvider)
            .handle(const UnexpectedException('스토어 열기 실패'));
      }
    } on Object catch (error) {
      if (mounted) {
        ref.read(errorHandlerProvider).handle(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningStore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeUrl = ref.watch(appUpdateControllerProvider)?.storeUrl;
    return PopScope(
      canPop: false,
      child: BottomActionScreenLayout(
        content: const UpdateRequiredContent(),
        bottomAction: PrimaryFilledButton(
          label: '업데이트하기',
          onPressed: storeUrl != null ? () => _openStore(storeUrl) : null,
          isLoading: _isOpeningStore,
        ),
      ),
    );
  }
}
