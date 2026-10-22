import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/router/app_routes.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/heading/screen_title_with_description_heading.dart';
import 'package:teeq/core/ui/layout/bottom_action_screen_layout.dart';
import 'package:teeq/core/ui/tag/accent_outline_hint_tag.dart';
import 'package:teeq/core/ui/text_field/outlined_box_text_field.dart';
import 'package:teeq/features/onboarding/data/ai_character_repository_impl.dart';
import 'package:teeq/features/onboarding/domain/character_name_rule.dart';
import 'package:teeq/features/onboarding/presentation/character_setup_flow_controller.dart';
import 'package:teeq/features/onboarding/presentation/widgets/character_naming_illustration.dart';

/// 생성된 캐릭터의 이름을 받아 확정하고 결과 화면으로 이동하는 화면.
class CharacterNameScreen extends ConsumerStatefulWidget {
  const CharacterNameScreen({super.key});

  @override
  ConsumerState<CharacterNameScreen> createState() =>
      _CharacterNameScreenState();
}

class _CharacterNameScreenState extends ConsumerState<CharacterNameScreen> {
  late final TextEditingController _nameController = TextEditingController(
    text: ref.read(characterSetupFlowControllerProvider).character?.name ?? '',
  );
  bool _isRequestInProgress = false;

  bool get _canSubmit =>
      characterNamePattern.hasMatch(_nameController.text) &&
      !_isRequestInProgress;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isRequestInProgress) {
      return;
    }
    setState(() => _isRequestInProgress = true);
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final repository = ref.read(aiCharacterRepositoryProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    final flowController = ref.read(
      characterSetupFlowControllerProvider.notifier,
    );
    try {
      final character = await repository.confirmName(
        name: _nameController.text,
      );
      flowController.recordCharacter(character);
      if (!mounted) {
        return;
      }
      // 성공하면 화면이 곧 사라지므로 이동이 끝날 때까지 잠금을 유지한다.
      context.go(AppRoutes.characterResult);
    } on Object catch (error) {
      errorHandler.handle(error);
      if (mounted) {
        setState(() => _isRequestInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BottomActionScreenLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.space24),
            const ScreenTitleWithDescriptionHeading(
              title: '마지막으로,\n이 친구의 이름을 정해줘.',
              description: '너의 답변을 바탕으로 너와 잘 맞는 친구가 탄생했어.\n이제 너만의 별명을 붙여줘.',
            ),
            const SizedBox(height: AppSpacing.space40),
            const Center(child: CharacterNamingIllustration()),
            const SizedBox(height: AppSpacing.space8),
            const Center(
              child: AccentOutlineHintTag(message: '너의 티크 친구가 완성됐어!'),
            ),
            const SizedBox(height: AppSpacing.space24),
            OutlinedBoxTextField(
              hintText: '이 친구를 뭐라고 부를까?',
              controller: _nameController,
              enabled: !_isRequestInProgress,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  characterNameInputCharacterPattern,
                ),
                LengthLimitingTextInputFormatter(characterNameMaximumLength),
              ],
            ),
          ],
        ),
        bottomAction: PrimaryFilledButton(
          label: '이 이름으로 시작하기',
          onPressed: _canSubmit ? _submit : null,
        ),
      ),
    );
  }
}
