import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _listPath = '/';
const _detailPath = '/detail';
const _lockedPath = '/locked';

const _listText = '목록 화면';
const _detailText = '상세 화면';
const _lockedText = '잠긴 화면';
const _navigateButtonText = '이동';

/// 앱과 같은 라이브러리의 `MaterialApp.router`로 go_router가 앱 종류를 판별하게 한다.
Future<void> _pumpRouterApp(
  WidgetTester tester, {
  required void Function(BuildContext context) navigate,
}) async {
  final router = GoRouter(
    initialLocation: _listPath,
    routes: [
      GoRoute(
        path: _listPath,
        builder: (context, state) => Scaffold(
          body: Column(
            children: [
              const Text(_listText),
              TextButton(
                onPressed: () => navigate(context),
                child: const Text(_navigateButtonText),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: _detailPath,
        builder: (context, state) => const Scaffold(body: Text(_detailText)),
      ),
      GoRoute(
        path: _lockedPath,
        builder: (context, state) => const PopScope(
          canPop: false,
          child: Scaffold(body: Text(_lockedText)),
        ),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
}

/// 화면 왼쪽 가장자리에서 오른쪽으로 끌어 iOS 뒤로 가기 제스처를 흉내 낸다.
Future<void> _swipeFromLeftEdge(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(5, 300));
  for (var step = 0; step < 10; step++) {
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  final iosOnly = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets('iOS에서 push한 화면은 왼쪽 가장자리 스와이프로 이전 화면으로 돌아간다', (tester) async {
    await _pumpRouterApp(
      tester,
      navigate: (context) => context.push(_detailPath),
    );
    await tester.tap(find.text(_navigateButtonText));
    await tester.pumpAndSettle();
    expect(find.text(_detailText), findsOneWidget);

    await _swipeFromLeftEdge(tester);

    expect(find.text(_detailText), findsNothing);
    expect(find.text(_listText), findsOneWidget);
  }, variant: iosOnly);

  testWidgets('PopScope로 막은 화면은 스와이프해도 돌아가지 않는다', (tester) async {
    await _pumpRouterApp(
      tester,
      navigate: (context) => context.push(_lockedPath),
    );
    await tester.tap(find.text(_navigateButtonText));
    await tester.pumpAndSettle();

    await _swipeFromLeftEdge(tester);

    expect(find.text(_lockedText), findsOneWidget);
  }, variant: iosOnly);

  testWidgets('go로 이동한 화면은 스택에 이전 화면이 없어 스와이프해도 남는다', (tester) async {
    await _pumpRouterApp(
      tester,
      navigate: (context) => context.go(_detailPath),
    );
    await tester.tap(find.text(_navigateButtonText));
    await tester.pumpAndSettle();

    await _swipeFromLeftEdge(tester);

    expect(find.text(_detailText), findsOneWidget);
  }, variant: iosOnly);
}
