import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';

/// 성향 태그 칩 모음. 한 줄에 다 들어가지 않으면 태그 단위로 다음 줄에 가운데 정렬한다.
/// 태그 안의 문구는 줄바꿈하지 않는다.
class PersonalityTagRow extends StatelessWidget {
  const PersonalityTagRow({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.space8,
      runSpacing: AppSpacing.space8,
      children: [for (final tag in tags) AccentOutlineHintTag(message: tag)],
    );
  }
}
