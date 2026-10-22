import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';
import 'package:teeq/features/onboarding/domain/character_setup_mode.dart';
import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_result_screen_layout.dart';
import 'package:teeq/features/onboarding/presentation/widgets/edit_character_result_decoration.dart';
import 'package:teeq/features/onboarding/presentation/widgets/first_time_character_result_decoration.dart';

/// 이름 확정 뒤 보여 주는 결과 화면. 최초 가입과 수정 모드에서 문구와 버튼 동작이 다르다.
class CharacterResultScreen extends ConsumerWidget {
  const CharacterResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 홈으로 이동하며 흐름을 비워도 떠나는 화면이 다시 그려지지 않게 watch하지 않는다.
    final flowState = ref.read(characterSetupFlowControllerProvider);
    final name = flowState.character?.name;
    if (name == null) {
      return const SizedBox.shrink();
    }
    final isFirstTime = flowState.mode == CharacterSetupMode.firstTime;
    return PopScope(
      canPop: false,
      child: isFirstTime
          ? CharacterResultScreenLayout(
              title: '반가워!\n난 ${withCopulaParticle(name)}.',
              description: '너에 대해 알게 된 내용으로 모두 준비를 마쳤어.\n앞으로 잘 부탁해!',
              hintMessage: '홈에서 바로 대화를 시작할 수 있어.',
              buttonLabel: '대화 시작하기',
              onButtonPressed: () => _startConversation(context, ref),
              decoration: const FirstTimeCharacterResultDecoration(),
            )
          : CharacterResultScreenLayout(
              title: '${withSubjectParticle(name)}\n이렇게 바뀌었어!',
              description: '수정한 내용을 반영해서\n새로운 $name의 모습으로 준비했어.',
              hintMessage: '수정한 사항들이 모두 반영되었어!',
              buttonLabel: '홈으로 돌아가기',
              onButtonPressed: () => _returnHome(context, ref),
              decoration: const EditCharacterResultDecoration(),
            ),
    );
  }

  /// 서버가 이미 캐릭터를 저장했으므로 재조회 없이 member만 로컬에서 갱신한다.
  void _startConversation(BuildContext context, WidgetRef ref) {
    final memberController = ref.read(currentMemberControllerProvider.notifier);
    final member = ref.read(currentMemberControllerProvider);
    if (member != null) {
      memberController.update(member.copyWith(hasAiCharacter: true));
    }
    _returnHome(context, ref);
  }

  void _returnHome(BuildContext context, WidgetRef ref) {
    final flowController = ref.read(
      characterSetupFlowControllerProvider.notifier,
    );
    // 수정한 캐릭터가 홈에 바로 보이도록 홈 요약을 다시 불러오게 한다.
    ref.invalidate(homeSummaryProvider);
    context.go(AppRoutes.home);
    flowController.reset();
  }
}
