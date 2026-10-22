import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';

/// 프로필 사진 시트의 아바타. 사진이 없거나 불러오지 못하면 기본 아바타를 보여 주고,
/// [isUploading]이면 그 위에 스피너를 돌린다.
class ProfileImageSheetAvatar extends StatelessWidget {
  const ProfileImageSheetAvatar({
    super.key,
    required this.isUploading,
    this.profileImageUrl,
  });

  final bool isUploading;
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: AppLayout.avatarSize,
        height: AppLayout.avatarSize,
        color: AppColors.accentSoft,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _avatarImage(),
            if (isUploading)
              const SizedBox(
                width: AppLayout.iconSize,
                height: AppLayout.iconSize,
                child: CircularProgressIndicator(
                  color: AppColors.textPrimary,
                  strokeWidth: AppBorderWidths.progress,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarImage() {
    final defaultAvatar = Image.asset(
      AppAssets.defaultAvatarIllustration,
      width: AppLayout.avatarIllustrationSize,
      height: AppLayout.avatarIllustrationSize,
    );
    final url = profileImageUrl;
    if (url == null) {
      return defaultAvatar;
    }
    return Image.network(
      url,
      width: AppLayout.avatarSize,
      height: AppLayout.avatarSize,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => defaultAvatar,
    );
  }
}
