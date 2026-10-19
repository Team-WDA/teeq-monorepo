import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/home/presentation/widgets/call_start_button.dart';
import 'package:teeq/features/home/presentation/widgets/character_edit_entry_card.dart';
import 'package:teeq/features/home/presentation/widgets/greeting_message_card.dart';
import 'package:teeq/features/home/presentation/widgets/home_character_illustration.dart';
import 'package:teeq/features/home/presentation/widgets/personality_tag_row.dart';
import 'package:teeq/features/onboarding/presentation/character_edit_confirmation_dialog.dart';

/// 홈 화면. 하단 탭 바는 탭 셸이 제공하므로 여기서는 본문만 그린다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isEditDialogOpen = false;

  /// 팝업이 떠 있는 동안 같은 카드가 다시 눌려도 팝업을 또 띄우지 않는다.
  Future<void> _openEditDialog(String characterName) async {
    if (_isEditDialogOpen) {
      return;
    }
    setState(() => _isEditDialogOpen = true);
    try {
      await showCharacterEditConfirmationDialog(
        context,
        characterName: characterName,
      );
    } finally {
      if (mounted) {
        setState(() => _isEditDialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로그아웃·탈퇴 순간 회원이 비면 이전 회원 데이터를 지우고 오류 페이지로 새지 않게 비워 둔다.
    final memberId = ref.watch(
      currentMemberControllerProvider.select((member) => member?.memberId),
    );
    if (memberId == null) {
      return const SizedBox.shrink();
    }
    ref.listen(homeSummaryProvider(memberId), (previous, next) {
      if (next case AsyncError(:final error)) {
        ref.read(errorHandlerProvider).handle(error, blocking: true);
      }
    });
    final summary = ref.watch(homeSummaryProvider(memberId)).value;
    if (summary == null) {
      return const SizedBox.shrink();
    }
    return _HomeContent(
      summary: summary,
      onEditCharacter: () => _openEditDialog(summary.characterName),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.summary, required this.onEditCharacter});

  final HomeSummary summary;
  final VoidCallback onEditCharacter;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = EdgeInsets.symmetric(
      horizontal: AppLayout.horizontalMargin,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            // 남는 세로 공간은 세 덩어리 사이에 균등하게 나뉘어 일러스트가 가운데 놓인다.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: horizontalPadding.copyWith(top: AppSpacing.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SvgPicture.asset(
                          AppAssets.brandLogo,
                          width: AppLayout.brandLogoWidth,
                          height: AppLayout.brandLogoHeight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space24),
                      GreetingMessageCard(message: summary.greeting),
                    ],
                  ),
                ),
                const HomeCharacterIllustration(),
                Padding(
                  padding: horizontalPadding.copyWith(
                    top: AppSpacing.space12,
                    bottom: AppSpacing.space20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        summary.characterName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading20Bold,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      PersonalityTagRow(tags: summary.personalityTags),
                      const SizedBox(height: AppSpacing.space24),
                      const CallStartButton(),
                      const SizedBox(height: AppSpacing.space8),
                      CharacterEditEntryCard(onTap: onEditCharacter),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
