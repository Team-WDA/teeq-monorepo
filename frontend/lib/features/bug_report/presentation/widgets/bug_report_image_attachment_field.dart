import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/bug_report/data/image_picker_bug_report_image_picker.dart';
import 'package:teeq/features/bug_report/domain/bug_report_input_limits.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_attachment_add_tile.dart';
import 'package:teeq/features/bug_report/presentation/widgets/bug_report_attachment_thumbnail.dart';

/// 제보에 붙일 이미지를 고르고 썸네일로 보여 주는 영역. 최대 5장까지 붙인다.
/// 붙은 경로 목록은 부모가 보관하고, 바뀔 때마다 [onChanged]로 새 목록을 받는다.
class BugReportImageAttachmentField extends ConsumerStatefulWidget {
  const BugReportImageAttachmentField({
    super.key,
    required this.imagePaths,
    required this.onChanged,
    this.isEnabled = true,
  });

  final List<String> imagePaths;
  final ValueChanged<List<String>> onChanged;

  /// false이면 사진을 더하거나 뺄 수 없다.
  final bool isEnabled;

  @override
  ConsumerState<BugReportImageAttachmentField> createState() =>
      _BugReportImageAttachmentFieldState();
}

class _BugReportImageAttachmentFieldState
    extends ConsumerState<BugReportImageAttachmentField> {
  bool _isPicking = false;

  Future<void> _pickImages() async {
    // 선택기가 열려 있는 동안의 연속 탭을 막는다.
    if (_isPicking) {
      return;
    }
    final remainingCount =
        BugReportInputLimits.imageMaxCount - widget.imagePaths.length;
    if (remainingCount <= 0) {
      return;
    }
    _isPicking = true;
    final picker = ref.read(bugReportImagePickerProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      final pickedPaths = await picker.pick(limit: remainingCount);
      if (!mounted || pickedPaths.isEmpty) {
        return;
      }
      widget.onChanged(
        BugReportInputLimits.mergeImagePaths(widget.imagePaths, pickedPaths),
      );
    } on Object catch (error) {
      errorHandler.handle(error);
    } finally {
      _isPicking = false;
    }
  }

  void _remove(String imagePath) {
    widget.onChanged(
      List.unmodifiable(widget.imagePaths.where((path) => path != imagePath)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePaths = widget.imagePaths;
    final isEnabled = widget.isEnabled;
    return Wrap(
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: [
        for (final imagePath in imagePaths)
          BugReportAttachmentThumbnail(
            key: ValueKey(imagePath),
            imagePath: imagePath,
            onDeletePressed: isEnabled ? () => _remove(imagePath) : null,
          ),
        if (imagePaths.length < BugReportInputLimits.imageMaxCount)
          BugReportAttachmentAddTile(
            attachedCount: imagePaths.length,
            maxCount: BugReportInputLimits.imageMaxCount,
            onPressed: isEnabled ? _pickImages : null,
          ),
      ],
    );
  }
}
