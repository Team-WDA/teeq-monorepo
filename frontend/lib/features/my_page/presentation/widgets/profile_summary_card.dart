import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 마이 화면 상단의 프로필 카드. 아바타(연필 배지 포함), 닉네임, 이메일, `>`를 보여 준다.
/// 카드 전체는 [onTap]을, 연필 배지는 [onEditPhotoTap]을 받는다. 배지 탭은 카드 탭으로 올라가지 않는다.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.nickname,
    this.email,
    this.profileImageUrl,
    this.onTap,
    this.onEditPhotoTap,
  });

  final String nickname;
  final String? email;

  /// 서버가 조립한 절대 URL. 없거나 불러오지 못하면 기본 아바타를 보여 준다.
  final String? profileImageUrl;

  final VoidCallback? onTap;
  final VoidCallback? onEditPhotoTap;

  @override
  Widget build(BuildContext context) {
    final emailText = email;
    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppLayout.profileCardHeight,
        ),
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: AppColors.accentSoft,
            width: AppBorderWidths.thin,
          ),
        ),
        child: Row(
          children: [
            _AvatarWithEditBadge(
              imageUrl: profileImageUrl,
              onEditPhotoTap: onEditPhotoTap,
            ),
            const SizedBox(width: AppSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading20Bold,
                  ),
                  if (emailText != null) ...[
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      emailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space16),
            SvgPicture.asset(
              AppAssets.chevronRightIcon,
              width: AppLayout.iconSize,
              height: AppLayout.iconSize,
              colorFilter: const ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return card;
    }
    // 연필 배지는 자기 접근성 노드를 유지해야 하므로 자식 노드를 합치지 않는다.
    return Semantics(
      button: true,
      container: true,
      explicitChildNodes: true,
      label: '닉네임 변경',
      onTap: onTap,
      child: card,
    );
  }
}

class _AvatarWithEditBadge extends StatelessWidget {
  const _AvatarWithEditBadge({
    required this.imageUrl,
    required this.onEditPhotoTap,
  });

  final String? imageUrl;
  final VoidCallback? onEditPhotoTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.avatarGroupWidth,
      height: AppLayout.avatarSize,
      child: Stack(
        children: [
          ClipOval(
            child: Container(
              width: AppLayout.avatarSize,
              height: AppLayout.avatarSize,
              color: AppColors.accentSoft,
              alignment: Alignment.center,
              child: _avatarImage(),
            ),
          ),
          // 탭 영역은 48x48이고 시각 크기 28x28인 배지는 그 안쪽 오른쪽 아래에 둔다.
          // 영역이 아바타 묶음 밖으로 나가면 탭을 받지 못하므로 묶음의 오른쪽 아래 모서리에 맞춘다.
          Positioned(
            left: AppLayout.avatarGroupWidth - AppLayout.minimumTapTarget,
            top: AppLayout.avatarSize - AppLayout.minimumTapTarget,
            width: AppLayout.minimumTapTarget,
            height: AppLayout.minimumTapTarget,
            // 콜백이 없어도 탭을 흡수해 카드 탭으로 올라가지 않게 한다.
            // 콜백이 없는 동안은 동작하지 않으므로 접근성 트리에서 뺀다.
            child: ExcludeSemantics(
              excluding: onEditPhotoTap == null,
              child: Semantics(
                button: true,
                label: '프로필 사진 변경',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEditPhotoTap ?? () {},
                  child: Stack(
                    children: [
                      Positioned(
                        left:
                            AppLayout.avatarEditBadgeLeft -
                            (AppLayout.avatarGroupWidth -
                                AppLayout.minimumTapTarget),
                        top:
                            AppLayout.avatarEditBadgeTop -
                            (AppLayout.avatarSize - AppLayout.minimumTapTarget),
                        child: Container(
                          width: AppLayout.avatarEditBadgeSize,
                          height: AppLayout.avatarEditBadgeSize,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            AppAssets.pencilIcon,
                            width: AppLayout.avatarEditIconSize,
                            height: AppLayout.avatarEditIconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarImage() {
    final defaultAvatar = Image.asset(
      AppAssets.defaultAvatarIllustration,
      width: AppLayout.avatarIllustrationSize,
      height: AppLayout.avatarIllustrationSize,
    );
    final url = imageUrl;
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
