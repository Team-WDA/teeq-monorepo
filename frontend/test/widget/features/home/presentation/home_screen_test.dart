import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/current_member_controller.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/member.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/core/error/error_handler.dart';
import 'package:teeq/features/home/data/home_repository_impl.dart';
import 'package:teeq/features/home/domain/home_summary.dart';
import 'package:teeq/features/home/presentation/home_screen.dart';
import 'package:teeq/features/home/presentation/widgets/character_edit_entry_card.dart';

import '../../../../support/fake_home_repository.dart';
import '../../../../support/viewport_cases.dart';

class _RecordingErrorHandler extends Fake implements ErrorHandler {
  final List<({Object error, bool blocking})> handledErrors = [];

  @override
  void handle(Object error, {bool blocking = false}) {
    handledErrors.add((error: error, blocking: blocking));
  }
}

const _member = Member(
  memberId: 'member-1',
  nickname: '소연',
  hasAiCharacter: true,
  loginType: LoginType.email,
);

const _summary = HomeSummary(
  characterName: '티티',
  personalityTags: ['다정함', '차분함', '유쾌함'],
  greeting: '소연아,\n오늘 하루 어땠어?',
);

({ProviderContainer container, _RecordingErrorHandler errorHandler}) _setUp(
  FakeHomeRepository repository,
) {
  final errorHandler = _RecordingErrorHandler();
  final container = ProviderContainer(
    // 실패 응답이 재시도되지 않도록 한다.
    retry: (retryCount, error) => null,
    overrides: [
      homeRepositoryProvider.overrideWithValue(repository),
      errorHandlerProvider.overrideWithValue(errorHandler),
    ],
  );
  addTearDown(container.dispose);
  container.read(currentMemberControllerProvider.notifier).update(_member);
  return (container: container, errorHandler: errorHandler);
}

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.light,
    home: const Scaffold(body: SafeArea(child: HomeScreen())),
  ),
);

Future<void> _pumpHome(
  WidgetTester tester,
  ProviderContainer container, {
  ViewportCase viewport = const ViewportCase(
    width: 393,
    height: 852,
    textScale: 1.0,
  ),
}) => pumpAtViewport(tester, viewport, _app(container));

void main() {
  testWidgets('shows greeting name and tags', (tester) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    expect(find.text('소연아,\n오늘 하루 어땠어?'), findsOneWidget);
    expect(find.text('티티'), findsOneWidget);
    for (final tag in _summary.personalityTags) {
      expect(find.text(tag), findsOneWidget);
    }
    expect(find.text('통화하기'), findsOneWidget);
    expect(find.text('캐릭터 수정'), findsOneWidget);
  });

  testWidgets('shows character name on a single line with ellipsis', (
    tester,
  ) async {
    final setUp = _setUp(
      FakeHomeRepository(
        summary: _summary.copyWith(characterName: '가나다라마바사아자차'),
      ),
    );
    await _pumpHome(
      tester,
      setUp.container,
      viewport: const ViewportCase(width: 320, height: 568, textScale: 1.2),
    );

    final nameText = tester.widget<Text>(find.text('가나다라마바사아자차'));
    expect(nameText.maxLines, 1);
    expect(nameText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders nothing while loading', (tester) async {
    final gate = Completer<void>();
    final setUp = _setUp(FakeHomeRepository(summary: _summary, gate: gate));
    await _pumpHome(tester, setUp.container);
    // 응답이 오기 전에는 스피너 없이 비어 있다.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('통화하기'), findsNothing);
    expect(find.text('티티'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('티티'), findsOneWidget);
  });

  testWidgets('reports error with blocking true when load fails', (
    tester,
  ) async {
    final failure = Exception('load failed');
    final setUp = _setUp(FakeHomeRepository(error: failure));
    await _pumpHome(tester, setUp.container);

    expect(setUp.errorHandler.handledErrors, hasLength(1));
    expect(setUp.errorHandler.handledErrors.single.error, failure);
    expect(setUp.errorHandler.handledErrors.single.blocking, isTrue);
    expect(find.text('통화하기'), findsNothing);
  });

  testWidgets('call button does nothing', (tester) async {
    final repository = FakeHomeRepository(summary: _summary);
    final setUp = _setUp(repository);
    await _pumpHome(tester, setUp.container);

    await tester.tap(find.text('통화하기'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(repository.fetchCount, 1);
    expect(setUp.errorHandler.handledErrors, isEmpty);
  });

  testWidgets('edit card opens edit confirmation dialog with character name', (
    tester,
  ) async {
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    await tester.tap(find.byType(CharacterEditEntryCard));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('티티의 성향을 다시 설정할까?'), findsOneWidget);
  });

  testWidgets(
    'logout clears member so home renders nothing without error page',
    (tester) async {
      final setUp = _setUp(FakeHomeRepository(summary: _summary));
      await _pumpHome(tester, setUp.container);
      expect(find.text('티티'), findsOneWidget);

      setUp.container.read(currentMemberControllerProvider.notifier).clear();
      await tester.pumpAndSettle();

      expect(find.text('티티'), findsNothing);
      expect(find.text('통화하기'), findsNothing);
      expect(setUp.errorHandler.handledErrors, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('meets tap target guidelines at the default viewport', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final setUp = _setUp(FakeHomeRepository(summary: _summary));
    await _pumpHome(tester, setUp.container);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  group('responsive layout', () {
    for (final viewport in viewportCases) {
      testWidgets('has no exception at ${viewport.label}', (tester) async {
        final longSummary = HomeSummary(
          characterName: '가나다라마바사아자차',
          personalityTags: ['가' * 50, '나' * 50, '다' * 50],
          greeting: List.filled(4, '가' * 45).join('\n'),
        );
        final setUp = _setUp(FakeHomeRepository(summary: longSummary));
        await _pumpHome(tester, setUp.container, viewport: viewport);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
