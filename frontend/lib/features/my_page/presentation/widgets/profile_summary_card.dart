import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_border_widths.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 마이 화면 상단의 프로필 카드. 아바타(연필 배지 포함), 닉네임, 이메일, `>`를 보여 주며 탭 동작은 없다.
class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.nickname,
    this.email,
    this.profileImageUrl,
  });

  final String nickname;
  final String? email;

  /// 서버가 조립한 절대 URL. 없거나 불러오지 못하면 기본 아바타를 보여 준다.
  final String? profileImageUrl;

  @override
  Widget build(BuildContext context) {
    final emailText = email;
    return Container(
      constraints: const BoxConstraints(minHeight: AppLayout.profileCardHeight),
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
          _AvatarWithEditBadge(imageUrl: profileImageUrl),
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
    );
  }
}

class _AvatarWithEditBadge extends StatelessWidget {
  const _AvatarWithEditBadge({required this.imageUrl});

  final String? imageUrl;

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
          Positioned(
            left: AppLayout.avatarEditBadgeLeft,
            top: AppLayout.avatarEditBadgeTop,
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
