import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/config/app_version_provider.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/ui/button/destructive_tonal_button.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/my_page/presentation/account_withdrawal_confirmation_dialog.dart';
import 'package:teeq/features/my_page/presentation/widgets/profile_summary_card.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_row.dart';
import 'package:teeq/features/my_page/presentation/widgets/settings_section_card.dart';

/// 마이 화면. 하단 탭 바는 탭 셸이 제공하므로 여기서는 본문만 그린다.
class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  bool _isLogoutInProgress = false;

  @override
  void initState() {
    super.initState();
    // 로그인 응답에 없는 이메일을 채우려고 진입할 때 한 번 회원 정보를 새로 받는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 탭 전환으로 첫 프레임 전에 화면이 사라졌다면 ref를 쓰지 않는다.
      if (mounted) {
        _refreshMember();
      }
    });
  }

  Future<void> _refreshMember() async {
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      await authFlow.refreshMember();
    } on Object catch (error) {
      errorHandler.handle(error);
    }
  }

  /// 로그아웃은 서버 실패와 무관하게 항상 로그아웃 상태로 끝나므로 재진입만 막는다.
  void _logout() {
    if (_isLogoutInProgress) {
      return;
    }
    _isLogoutInProgress = true;
    ref.read(authFlowProvider).logout();
  }

  @override
  Widget build(BuildContext context) {
    // 로그아웃·탈퇴 순간 회원이 비면 이전 회원 정보를 그리지 않는다.
    final member = ref.watch(currentMemberControllerProvider);
    if (member == null) {
      return const SizedBox.shrink();
    }
    // 버전을 못 읽으면(로딩·오류) 버전 표기 없이 '서비스'만 보여 주고 에러 처리는 하지 않는다.
    final appVersion = ref.watch(appVersionProvider).value;
    final serviceSectionTitle = appVersion == null
        ? '서비스'
        : '서비스 (앱정보 v$appVersion)';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.horizontalMargin,
        AppSpacing.space4,
        AppLayout.horizontalMargin,
        AppSpacing.space24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('마이', style: AppTextStyles.display),
          const SizedBox(height: AppSpacing.space24),
          ProfileSummaryCard(
            nickname: member.nickname ?? '',
            email: member.email,
            profileImageUrl: member.profileImageUrl,
          ),
          const SizedBox(height: AppSpacing.space24),
          SettingsSectionCard(
            title: '계정 정보',
            rows: [
              SettingsRow(
                label: '이메일',
                leadingIconAssetPath: AppAssets.mailIcon,
                value: member.email,
              ),
              // 비밀번호가 없는 회원(Apple 등)에게는 숨긴다.
              if (member.loginType == LoginType.email)
                const SettingsRow(
                  label: '비밀번호 변경',
                  leadingIconAssetPath: AppAssets.lockIcon,
                  showsChevron: true,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space24),
          SettingsSectionCard(
            title: serviceSectionTitle,
            rows: const [
              SettingsRow(
                label: '서비스 이용약관',
                leadingIconAssetPath: AppAssets.documentIcon,
                showsChevron: true,
              ),
              SettingsRow(
                label: '개인정보 처리방침',
                leadingIconAssetPath: AppAssets.lockIcon,
                showsChevron: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space52),
          DestructiveTonalButton(label: '로그아웃', onPressed: _logout),
          const SizedBox(height: AppSpacing.space4),
          DestructiveTonalButton(
            label: '회원 탈퇴',
            onPressed: () => showAccountWithdrawalConfirmationDialog(context),
          ),
        ],
      ),
    );
  }
}
