import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/core/error/error_messages.dart';
import 'package:teeq/core/ui/button/primary_filled_button.dart';
import 'package:teeq/core/ui/decoration/soft_glow_decoration.dart';
import 'package:teeq/core/ui/text_field/committed_text_editing_value.dart';
import 'package:teeq/features/auth/domain/nickname_input_rule.dart';
import 'package:teeq/features/auth/presentation/auth_flow_provider.dart';
import 'package:teeq/features/my_page/presentation/widgets/back_button_with_centered_title_header.dart';
import 'package:teeq/features/my_page/presentation/widgets/nickname_helper_with_speech_bubble.dart';
import 'package:teeq/features/my_page/presentation/widgets/nickname_input_section.dart';

/// 마이 화면의 프로필 카드에서 들어오는 닉네임 변경 화면.
class NicknameChangeScreen extends ConsumerStatefulWidget {
  const NicknameChangeScreen({super.key});

  @override
  ConsumerState<NicknameChangeScreen> createState() =>
      _NicknameChangeScreenState();
}

class _NicknameChangeScreenState extends ConsumerState<NicknameChangeScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isRequestInProgress = false;
  bool _isDuplicateNickname = false;

  String get _input => _nicknameController.text;

  bool get _canSubmit =>
      !_isRequestInProgress &&
      NicknameInputRule.isSubmittable(
        _input,
        ref.watch(
              currentMemberControllerProvider.select(
                (member) => member?.nickname,
              ),
            ) ??
            '',
      );

  @override
  void initState() {
    super.initState();
    // IME 조합이 끝나도 글자가 그대로면 onChanged가 오지 않으므로 컨트롤러 변경을 직접 듣는다.
    _nicknameController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _nicknameController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onNicknameChanged(String _) {
    // 입력이 바뀌면 이전 중복 응답은 더 이상 유효하지 않다.
    setState(() => _isDuplicateNickname = false);
  }

  Future<void> _submit() async {
    // 리빌드 전에 들어오는 연속 탭도 막는다.
    if (_isRequestInProgress) {
      return;
    }
    setState(() => _isRequestInProgress = true);
    // 화면이 먼저 사라져도 오류를 전달할 수 있게 await 전에 가져온다.
    final authFlow = ref.read(authFlowProvider);
    final errorHandler = ref.read(errorHandlerProvider);
    try {
      await authFlow.changeNickname(_input);
      if (!mounted) {
        return;
      }
      // 성공하면 화면이 곧 사라지므로 이동이 끝날 때까지 잠금을 유지한다.
      context.pop();
    } on Object catch (error) {
      final isDuplicate =
          error is ApiException &&
          error.errorCode == ErrorCode.duplicateNickname;
      if (isDuplicate) {
        if (mounted) {
          setState(() {
            _isDuplicateNickname = true;
            _isRequestInProgress = false;
          });
        }
        return;
      }
      errorHandler.handle(error);
      if (mounted) {
        setState(() => _isRequestInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 화면 폭을 넘어 번지는 장식이라 헤더·본문 뒤에 깔고 터치를 받지 않는다.
            Positioned(
              top:
                  AppLayout.nicknameGlowCenterOffsetY -
                  AppLayout.namingGlowSize / 2,
              left: 0,
              right: 0,
              height: AppLayout.namingGlowSize,
              child: const OverflowBox(
                minWidth: 0,
                maxWidth: AppLayout.namingGlowSize,
                child: SoftGlowDecoration(
                  assetPath: AppAssets.glowNaming,
                  width: AppLayout.namingGlowSize,
                  height: AppLayout.namingGlowSize,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BackButtonWithCenteredTitleHeader(
                  title: '닉네임 변경',
                  onBackPressed: () => context.pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppLayout.horizontalMargin,
                      AppSpacing.space20,
                      AppLayout.horizontalMargin,
                      AppSpacing.space24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const NicknameHelperWithSpeechBubble(),
                        const SizedBox(height: AppSpacing.space28),
                        NicknameInputSection(
                          controller: _nicknameController,
                          onChanged: _onNicknameChanged,
                          enabled: !_isRequestInProgress,
                          issue: NicknameInputRule.issueOf(
                            _nicknameController.value.committedText,
                          ),
                          duplicateErrorMessage: _isDuplicateNickname
                              ? ErrorCode.duplicateNickname.userMessage
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.horizontalMargin,
                    0,
                    AppLayout.horizontalMargin,
                    AppSpacing.space12,
                  ),
                  child: PrimaryFilledButton(
                    label: '저장하기',
                    onPressed: _canSubmit ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
