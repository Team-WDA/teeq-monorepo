import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';

/// 업데이트 안내 화면의 가운데 정렬 제목과 설명.
/// 디자인 시안이 없어 일러스트·아이콘 없이 문구만 둔다.
class UpdateRequiredContent extends StatelessWidget {
  const UpdateRequiredContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.space52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '업데이트가 필요해요',
            textAlign: TextAlign.center,
            style: AppTextStyles.title24Bold,
          ),
          SizedBox(height: AppSpacing.space12),
          Text(
            '더 안전하고 편하게 TeeQ를 쓰려면 최신 버전으로 업데이트해 주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body16RegularMultiline,
          ),
        ],
      ),
    );
  }
}
