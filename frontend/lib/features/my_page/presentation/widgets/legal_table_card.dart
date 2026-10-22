import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_radius.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/features/my_page/domain/legal_document.dart';

/// 제목과 `라벨 / 값` 행을 위아래로 쌓은 회색 카드(약관의 표).
class LegalTableCard extends StatelessWidget {
  const LegalTableCard({super.key, required this.table});

  final LegalTable table;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.documentCardSurface,
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.space8,
          children: [
            Text(table.title, style: AppTextStyles.body14BoldMultiline),
            for (final row in table.rows) ...[
              Text(row.label, style: AppTextStyles.caption12BoldMultiline),
              Text(row.value, style: AppTextStyles.body14RegularMultiline),
            ],
          ],
        ),
      ),
    );
  }
}
