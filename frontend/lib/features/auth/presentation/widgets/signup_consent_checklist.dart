import 'package:material_ui/material_ui.dart';
import 'package:teeq/core/design/app_colors.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/ui/checkbox/rounded_square_checkbox.dart';

/// 가입 약관 동의 목록. 전체 동의는 두 항목에서 파생되는 값이다.
class SignupConsentChecklist extends StatelessWidget {
  const SignupConsentChecklist({
    super.key,
    required this.isServiceTermsAgreed,
    required this.isPrivacyPolicyAgreed,
    required this.onServiceTermsChanged,
    required this.onPrivacyPolicyChanged,
    required this.onServiceTermsDetailTap,
    required this.onPrivacyPolicyDetailTap,
  });

  final bool isServiceTermsAgreed;
  final bool isPrivacyPolicyAgreed;
  final ValueChanged<bool> onServiceTermsChanged;
  final ValueChanged<bool> onPrivacyPolicyChanged;
  final VoidCallback onServiceTermsDetailTap;
  final VoidCallback onPrivacyPolicyDetailTap;

  bool get _isAllAgreed => isServiceTermsAgreed && isPrivacyPolicyAgreed;

  void _changeAll(bool isAgreed) {
    onServiceTermsChanged(isAgreed);
    onPrivacyPolicyChanged(isAgreed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConsentRow(
          label: '전체 동의',
          labelStyle: AppTextStyles.body16Medium,
          isChecked: _isAllAgreed,
          onChanged: _changeAll,
        ),
        const SizedBox(height: AppSpacing.space8),
        _ConsentRow(
          label: '[필수] 서비스 이용약관 동의',
          labelStyle: AppTextStyles.body14Medium.copyWith(
            decoration: TextDecoration.underline,
          ),
          isChecked: isServiceTermsAgreed,
          onChanged: onServiceTermsChanged,
          onLabelTap: onServiceTermsDetailTap,
        ),
        const SizedBox(height: AppSpacing.space8),
        _ConsentRow(
          label: '[필수] 개인정보 수집·이용 동의',
          labelStyle: AppTextStyles.body14Medium.copyWith(
            decoration: TextDecoration.underline,
          ),
          isChecked: isPrivacyPolicyAgreed,
          onChanged: onPrivacyPolicyChanged,
          onLabelTap: onPrivacyPolicyDetailTap,
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          '필수 항목에 모두 동의하면 다음으로 진행할 수 있어.',
          style: AppTextStyles.caption12SemiBoldMultiline.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// 동의 한 줄. [onLabelTap]이 없으면 줄 전체가 토글 영역이고,
/// 있으면 체크박스만 토글하고 문구 영역은 상세 보기 탭 영역이다.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.label,
    required this.labelStyle,
    required this.isChecked,
    required this.onChanged,
    this.onLabelTap,
  });

  final String label;
  final TextStyle labelStyle;
  final bool isChecked;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    final onLabelTap = this.onLabelTap;
    if (onLabelTap == null) {
      return _buildWholeRowToggle();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppLayout.consentRowHeight),
      child: Row(
        children: [
          Semantics(
            button: true,
            checked: isChecked,
            label: label,
            onTap: () => onChanged(!isChecked),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(!isChecked),
              child: IgnorePointer(
                child: RoundedSquareCheckbox(
                  isChecked: isChecked,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space10),
          Expanded(
            child: Semantics(
              button: true,
              label: '$label 상세 보기',
              onTap: onLabelTap,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLabelTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppLayout.consentRowHeight,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(label, style: labelStyle),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWholeRowToggle() {
    return Semantics(
      button: true,
      checked: isChecked,
      label: label,
      onTap: () => onChanged(!isChecked),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!isChecked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.consentRowHeight,
          ),
          child: Row(
            children: [
              IgnorePointer(
                child: RoundedSquareCheckbox(
                  isChecked: isChecked,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: AppSpacing.space10),
              Expanded(child: Text(label, style: labelStyle)),
            ],
          ),
        ),
      ),
    );
  }
}
