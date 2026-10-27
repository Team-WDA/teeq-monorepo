import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/bottom_sheet/app_bottom_sheet.dart';
import 'package:teeq/core/ui/button/app_close_button.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/my_page/data/image_picker_profile_image_picker.dart';
import 'package:teeq/features/my_page/domain/profile_image_rule.dart';
import 'package:teeq/features/my_page/presentation/widgets/profile_image_sheet_avatar.dart';
import 'package:teeq/features/my_page/presentation/widgets/profile_image_sheet_cancel_button.dart';

/// 프로필 사진 변경 시트를 띄운다. 스크림 탭·스와이프·뒤로 가기로는 닫히지 않고,
/// ✕와 [취소]로만 닫힌다(업로드 중에는 둘 다 비활성). 사진을 올리는 데 성공하면 스스로 닫힌다.
Future<void> showProfileImageSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const _ProfileImageSheetContent(),
  );
}

class _ProfileImageSheetContent extends ConsumerStatefulWidget {
  const _ProfileImageSheetContent();

  @override
  ConsumerState<_ProfileImageSheetContent> createState() =>
      _ProfileImageSheetContentState();
}

class _ProfileImageSheetContentState
    extends ConsumerState<_ProfileImageSheetContent> {
  bool _isPicking = false;
  bool _isUploading = false;
  ProfileImageIssue? _issue;

  /// 닫히는 중인 시트에서 한 번 더 눌려도 아래 화면까지 닫히지 않게 현재 경로일 때만 닫는다.
  void _close() {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _selectPhoto() async {
    // 선택기가 열려 있거나 업로드 중이면 다시 들어오지 않는다. 리빌드 전의 연속 탭도 막는다.
    if (_isPicking || _isUploading) {
      return;
    }
    _isPicking = true;
    final profileImagePicker = ref.read(profileImagePickerProvider);
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      final image = await profileImagePicker.pick();
      // 선택을 취소했다면 아무것도 바꾸지 않는다.
      if (image == null || !mounted) {
        return;
      }
      final issue = ProfileImageRule.issueOf(
        fileName: image.fileName,
        byteLength: image.bytes.length,
      );
      if (issue != null) {
        setState(() => _issue = issue);
        return;
      }
      setState(() {
        _issue = null;
        _isUploading = true;
      });
      await authFlow.replaceProfileImage(image);
      if (mounted) {
        _close();
      }
    } on Object catch (error) {
      errorHandler.handle(error);
      if (mounted) {
        setState(() => _isUploading = false);
      }
    } finally {
      _isPicking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = ref.watch(
      currentMemberControllerProvider.select(
        (member) => member?.profileImageUrl,
      ),
    );
    final issue = _issue;
    return SingleChildScrollView(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.horizontalMargin,
              AppSpacing.space40,
              AppLayout.horizontalMargin,
              AppSpacing.space14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '프로필 사진 변경',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading20Medium,
                ),
                const SizedBox(height: AppSpacing.space16),
                Center(
                  child: ProfileImageSheetAvatar(
                    isUploading: _isUploading,
                    profileImageUrl: profileImageUrl,
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                const Text(
                  'JPG·PNG 파일을 선택해줘.\n최대 5MB까지 올릴 수 있어.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption12MediumMultiline,
                ),
                if (issue != null) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    _issueMessage(issue),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption12MediumMultiline.copyWith(
                      color: AppColors.destructiveText,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space16),
                PrimaryFilledButton(
                  label: '사진 선택하기',
                  isLoading: _isUploading,
                  onPressed: _selectPhoto,
                ),
                const SizedBox(height: AppSpacing.space8),
                ProfileImageSheetCancelButton(
                  onPressed: _isUploading ? null : _close,
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.space8,
            right: AppSpacing.space12,
            child: AppCloseButton(onPressed: _isUploading ? null : _close),
          ),
        ],
      ),
    );
  }

  String _issueMessage(ProfileImageIssue issue) => switch (issue) {
    ProfileImageIssue.unsupportedFormat => 'JPG, PNG 파일만 올릴 수 있어.',
    ProfileImageIssue.tooLarge => '5MB 이하의 사진만 올릴 수 있어.',
  };
}
