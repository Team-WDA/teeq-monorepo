import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_radius.dart';

/// 첨부한 이미지 한 장의 썸네일. 오른쪽 위 ✕로 이 이미지만 뺀다([onDeletePressed]가 null이면 비활성).
class BugReportAttachmentThumbnail extends StatelessWidget {
  const BugReportAttachmentThumbnail({
    super.key,
    required this.imagePath,
    required this.onDeletePressed,
  });

  final String imagePath;
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    // 작은 타일에 원본 해상도를 디코딩하지 않도록 타일 크기(물리 픽셀)로 제한한다.
    final decodeSize =
        (AppLayout.bugReportAttachmentSize *
                MediaQuery.devicePixelRatioOf(context))
            .round();
    return SizedBox(
      width: AppLayout.bugReportAttachmentSize,
      height: AppLayout.bugReportAttachmentSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: AppRadius.borderRadiusSm,
              child: Image(
                // fit 정책으로 가로세로 비율을 유지한 채 디코딩 크기만 제한한다.
                image: ResizeImage(
                  FileImage(File(imagePath)),
                  width: decodeSize,
                  height: decodeSize,
                  policy: ResizeImagePolicy.fit,
                ),
                fit: BoxFit.cover,
                // 파일을 못 읽어도 자리는 유지해 삭제할 수 있게 한다.
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: AppColors.neutralSurface),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Semantics(
              button: true,
              enabled: onDeletePressed != null,
              label: '첨부 사진 삭제',
              onTap: onDeletePressed,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDeletePressed,
                child: SizedBox(
                  width: AppLayout.minimumTapTarget,
                  height: AppLayout.minimumTapTarget,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.scrim,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: AppLayout.iconSize,
                        height: AppLayout.iconSize,
                        child: Center(
                          child: SvgPicture.asset(
                            AppAssets.closeIcon,
                            width: AppLayout.smallIconSize,
                            height: AppLayout.smallIconSize,
                            colorFilter: const ColorFilter.mode(
                              AppColors.textOnDark,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
