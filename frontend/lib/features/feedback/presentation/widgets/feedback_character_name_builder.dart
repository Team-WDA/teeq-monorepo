import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/home/presentation/home_summary_provider.dart';

/// 홈 요약에서 캐릭터 이름을 읽어 [builder]에 넘긴다.
/// 이름이 도착하기 전에는 빈 화면을 그리고, 조회가 실패하면 홈과 같이 중앙 에러 처리에 맡긴다.
class FeedbackCharacterNameBuilder extends ConsumerWidget {
  const FeedbackCharacterNameBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, String characterName) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberId = ref.watch(
      currentMemberControllerProvider.select((member) => member?.memberId),
    );
    if (memberId == null) {
      return const Scaffold();
    }
    ref.listen(homeSummaryProvider(memberId), (previous, next) {
      if (next case AsyncError(:final error)) {
        // 이전 값이 있으면 화면을 유지한 채 알리기만 하고, 첫 조회 실패일 때만 막는다.
        ref.read(errorHandlerProvider).handle(error, blocking: !next.hasValue);
      }
    });
    final summary = ref.watch(homeSummaryProvider(memberId)).value;
    if (summary == null) {
      return const Scaffold();
    }
    return builder(context, summary.characterName);
  }
}
