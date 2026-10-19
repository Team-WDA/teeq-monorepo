import 'package:flutter/material.dart';
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
  });

  final bool isServiceTermsAgreed;
  final bool isPrivacyPolicyAgreed;
  final ValueChanged<bool> onServiceTermsChanged;
  final ValueChanged<bool> onPrivacyPolicyChanged;

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
        ),
        const SizedBox(height: AppSpacing.space8),
        _ConsentRow(
          label: '[필수] 개인정보 수집·이용 동의',
          labelStyle: AppTextStyles.body14Medium.copyWith(
            decoration: TextDecoration.underline,
          ),
          isChecked: isPrivacyPolicyAgreed,
          onChanged: onPrivacyPolicyChanged,
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

/// 체크박스와 문구를 한 탭 영역으로 묶은 동의 한 줄.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.label,
    required this.labelStyle,
    required this.isChecked,
    required this.onChanged,
  });

  final String label;
  final TextStyle labelStyle;
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
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
