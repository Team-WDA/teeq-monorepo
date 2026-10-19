import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/design/app_assets.dart';
import 'package:teeq/core/design/app_layout.dart';
import 'package:teeq/core/design/app_spacing.dart';
import 'package:teeq/core/design/app_text_styles.dart';
import 'package:teeq/core/design/app_theme.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_choice_chip.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_choice_group.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_reason_input_field.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_response_summary_card.dart';
import 'package:teeq/features/feedback/presentation/widgets/feedback_star_rating.dart';
import 'package:teeq/features/feedback/presentation/widgets/memory_not_applicable_check_row.dart';
import 'package:teeq/features/feedback/presentation/widgets/scaled_question_section.dart';
import 'package:teeq/features/feedback/presentation/widgets/start_reason_checklist.dart';

import '../../../../support/viewport_cases.dart';

const _contentWidth = 345.0;
const _gap = AppSpacing.space8;
const _defaultViewport = ViewportCase(width: 393, height: 852, textScale: 1.0);
const _narrowViewport = ViewportCase(width: 320, height: 568, textScale: 1.2);

Widget _wrap(Widget child, {double width = _contentWidth}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

int _countStars(WidgetTester tester, String assetName) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .where(
      (picture) =>
          picture.bytesLoader is SvgAssetLoader &&
          (picture.bytesLoader as SvgAssetLoader).assetName == assetName,
    )
    .length;

Widget _choiceGroup({
  required List<int> values,
  required int columnCount,
  Set<int> selected = const {},
  ValueChanged<int>? onTap,
  bool isEnabled = true,
}) => FeedbackChoiceGroup<int>(
  values: values,
  labelOf: (value) => '선택$value',
  selectedValues: selected,
  onTap: onTap ?? (_) {},
  columnCount: columnCount,
  isEnabled: isEnabled,
);

/// 테스트 기본 글꼴(Ahem)로는 줄바꿈을 잴 수 없으므로 실제 Pretendard를 불러온다.
Future<void> _loadPretendardFonts() async {
  final loader = FontLoader('Pretendard');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Pretendard-$weight.otf'));
  }
  await loader.load();
}

void main() {
  group('FeedbackChoiceGroup', () {
    testWidgets('choiceGroup_equalColumnsWrapAfterColumnCount', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(_choiceGroup(values: [1, 2, 3, 4, 5], columnCount: 3)),
      );

      final chips = find.byType(FeedbackChoiceChip);
      final expectedWidth = (_contentWidth - 2 * _gap) / 3;
      for (var index = 0; index < 5; index++) {
        expect(
          tester.getSize(chips.at(index)).width,
          closeTo(expectedWidth, 0.01),
        );
      }
      final firstRowTop = tester.getTopLeft(chips.at(0)).dy;
      expect(tester.getTopLeft(chips.at(2)).dy, firstRowTop);
      expect(tester.getTopLeft(chips.at(3)).dy, greaterThan(firstRowTop));
      expect(
        tester.getTopLeft(chips.at(4)).dy,
        tester.getTopLeft(chips.at(3)).dy,
      );
    });

    testWidgets('choiceGroup_longestRequiredLabelStaysOneLineAtDefaultScale', (
      tester,
    ) async {
      await _loadPretendardFonts();
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(
          FeedbackChoiceGroup<String>(
            values: const [
              '말이 끊겼어',
              '답이 늦었어',
              '맥락이 안 맞았어',
              '같은 말을 반복했어',
              '없었어',
            ],
            labelOf: (value) => value,
            selectedValues: const {},
            onTap: (_) {},
            columnCount: 3,
          ),
        ),
      );

      final chip = find.ancestor(
        of: find.text('같은 말을 반복했어'),
        matching: find.byType(FeedbackChoiceChip),
      );
      expect(tester.getSize(chip).height, AppLayout.feedbackChoiceHeight);
    });

    testWidgets('choiceGroup_scaleFiveColumns', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(_choiceGroup(values: [1, 2, 3, 4, 5], columnCount: 5)),
      );

      final chips = find.byType(FeedbackChoiceChip);
      expect(chips, findsNWidgets(5));
      expect(
        tester.getSize(chips.first).width,
        closeTo((_contentWidth - 4 * _gap) / 5, 0.01),
      );
      expect(
        tester.getSize(chips.first).height,
        AppLayout.feedbackChoiceHeight,
      );
    });

    testWidgets('choiceGroup_selectedChipUsesBoldStyle', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(_choiceGroup(values: [1, 2], columnCount: 2, selected: {1})),
      );

      expect(
        tester.widget<Text>(find.text('선택1')).style,
        AppTextStyles.body14Bold,
      );
      expect(
        tester.widget<Text>(find.text('선택2')).style,
        AppTextStyles.body14SemiBold,
      );
    });

    testWidgets('choiceGroup_disabledIgnoresTap', (tester) async {
      var tapCount = 0;
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(
          _choiceGroup(
            values: [1, 2],
            columnCount: 2,
            isEnabled: false,
            onTap: (_) => tapCount++,
          ),
        ),
      );

      await tester.tap(find.text('선택1'));
      expect(tapCount, 0);
    });

    testWidgets('choiceGroup_enabledReportsTappedValue', (tester) async {
      final tapped = <int>[];
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(_choiceGroup(values: [1, 2], columnCount: 2, onTap: tapped.add)),
      );

      await tester.tap(find.text('선택2'));
      expect(tapped, [2]);
    });
  });

  group('FeedbackStarRating', () {
    testWidgets('starRating_tappingSameStarKeepsValue', (tester) async {
      final changes = <int>[];
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(FeedbackStarRating(value: 3, onChanged: changes.add)),
      );

      final stars = find.byType(GestureDetector);
      await tester.tap(stars.at(2));
      expect(changes, [3]);
    });

    testWidgets('starRating_eachStarHasLabelAndSelectedState', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(FeedbackStarRating(value: 3, onChanged: (_) {})),
      );

      for (var score = 1; score <= FeedbackStarRating.starCount; score++) {
        expect(find.bySemanticsLabel('별 $score개'), findsOneWidget);
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('별 3개')),
        matchesSemantics(
          label: '별 3개',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasEnabledState: false,
        ),
      );
    });

    testWidgets('starRating_filledCountMatchesValue', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(FeedbackStarRating(value: 4, onChanged: (_) {})),
      );

      expect(_countStars(tester, AppAssets.feedbackStarFilledIcon), 4);
      expect(_countStars(tester, AppAssets.feedbackStarEmptyIcon), 1);
    });

    testWidgets('starRating_hasNoFilledStarWhenValueIsNull', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(FeedbackStarRating(value: null, onChanged: (_) {})),
      );

      expect(_countStars(tester, AppAssets.feedbackStarFilledIcon), 0);
      expect(_countStars(tester, AppAssets.feedbackStarEmptyIcon), 5);
    });

    testWidgets('starRating_touchTargetsMeetMinimum', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(FeedbackStarRating(value: 1, onChanged: (_) {})),
      );

      final target = tester.getSize(find.byType(GestureDetector).first);
      expect(target.width, greaterThanOrEqualTo(AppLayout.minimumTapTarget));
      expect(target.height, greaterThanOrEqualTo(AppLayout.minimumTapTarget));
    });
  });

  group('FeedbackReasonInputField', () {
    Widget field({
      required ValueChanged<String> onChanged,
      bool isEnabled = true,
      String text = '',
    }) => FeedbackReasonInputField(
      title: '이유를 한 줄로 알려줘. (선택)',
      example: '예) 좋았어.',
      text: text,
      onChanged: onChanged,
      maxLength: FeedbackInputLimits.reasonMaxLength,
      isEnabled: isEnabled,
    );

    testWidgets('reasonInput_enforcesMaxLength', (tester) async {
      String latest = '';
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(field(onChanged: (value) => latest = value)),
      );

      await tester.enterText(find.byType(TextField), '가' * 101);
      expect(latest.length, FeedbackInputLimits.reasonMaxLength);
    });

    testWidgets('reasonInput_doesNotSplitSurrogatePairAtLimit', (tester) async {
      String latest = '';
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(field(onChanged: (value) => latest = value)),
      );

      await tester.enterText(find.byType(TextField), '${'가' * 99}😀');

      expect(latest, '가' * 99);
    });

    testWidgets('reasonInput_hasAccessibleName', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(field(onChanged: (_) {})),
      );

      expect(find.bySemanticsLabel('이유를 한 줄로 알려줘. (선택)'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('reasonInput_disabledRejectsInput', (tester) async {
      String latest = '';
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(field(onChanged: (value) => latest = value, isEnabled: false)),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(latest, '');
    });

    testWidgets('reasonInput_showsTitleAndExampleUntilTyped', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(field(onChanged: (_) {})),
      );

      expect(find.text('이유를 한 줄로 알려줘. (선택)'), findsOneWidget);
      expect(find.text('예) 좋았어.'), findsOneWidget);
    });
  });

  group('MemoryNotApplicableCheckRow', () {
    testWidgets('memoryNotApplicableRow_togglesAndReportsChange', (
      tester,
    ) async {
      final changes = <bool>[];
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(
          MemoryNotApplicableCheckRow(isChecked: false, onChanged: changes.add),
        ),
      );

      await tester.tap(find.text('기억할 만한 내용이 없어서 평가하기 어려워.'));
      expect(changes, [true]);
    });

    testWidgets('memoryNotApplicableRow_checkedUsesCheckedCircle', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(MemoryNotApplicableCheckRow(isChecked: true, onChanged: (_) {})),
      );

      expect(_countStars(tester, AppAssets.radioCircleCheckedIcon), 1);
      expect(_countStars(tester, AppAssets.radioCircleIcon), 0);
    });
  });

  group('ScaledQuestionSection', () {
    Widget section({required bool isScoreEnabled}) => ScaledQuestionSection(
      title: '1. 질문',
      anchorLabels: const ['낮음', '보통', '높음'],
      score: 3,
      onScoreChanged: (_) {},
      reasonText: '',
      onReasonChanged: (_) {},
      reasonExample: '예) 예시',
      isScoreEnabled: isScoreEnabled,
      footer: const Text('푸터'),
    );

    testWidgets('scaledQuestion_disablesChipsAndReasonWhenScoreDisabled', (
      tester,
    ) async {
      var scoreChangeCount = 0;
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(
          ScaledQuestionSection(
            title: '1. 질문',
            anchorLabels: const ['낮음', '보통', '높음'],
            score: null,
            onScoreChanged: (_) => scoreChangeCount++,
            reasonText: '',
            onReasonChanged: (_) {},
            reasonExample: '예) 예시',
            isScoreEnabled: false,
          ),
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(FeedbackChoiceChip),
          matching: find.text('3'),
        ),
      );
      expect(scoreChangeCount, 0);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('scaledQuestion_showsAnchorsFiveChipsAndFooter', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(section(isScoreEnabled: true)),
      );

      expect(find.byType(FeedbackChoiceChip), findsNWidgets(5));
      expect(find.text('낮음'), findsOneWidget);
      expect(find.text('보통'), findsOneWidget);
      expect(find.text('높음'), findsOneWidget);
      expect(find.text('푸터'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });

    testWidgets('scaledQuestion_anchorNumbersSitAboveTheirLabels', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(section(isScoreEnabled: true)),
      );

      const anchors = {'1': '낮음', '3': '보통', '5': '높음'};
      for (final entry in anchors.entries) {
        final number = find.descendant(
          of: find.byType(Row),
          matching: find.text(entry.key),
        );
        final label = find.text(entry.value);
        expect(number, findsOneWidget);
        expect(
          tester.getTopLeft(number).dy,
          lessThan(tester.getTopLeft(label).dy),
        );
        expect(
          tester.getCenter(number).dx,
          closeTo(tester.getCenter(label).dx, tester.getSize(label).width),
        );
      }
    });
  });

  group('StartReasonChecklist', () {
    Widget checklist(Set<StartReason> selected) => StartReasonChecklist(
      characterName: '티티',
      selected: selected,
      onToggle: (_) {},
      otherText: '',
      onOtherTextChanged: (_) {},
    );

    testWidgets('startReasonChecklist_otherInputDisabledUntilOtherChecked', (
      tester,
    ) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(checklist({StartReason.needToTalk})),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

      await tester.pumpWidget(
        _wrap(checklist({StartReason.needToTalk, StartReason.other})),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    });

    testWidgets('startReasonChecklist_listsSixReasonsWithCharacterName', (
      tester,
    ) async {
      final toggled = <StartReason>[];
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(
          StartReasonChecklist(
            characterName: '티티',
            selected: const {},
            onToggle: toggled.add,
            otherText: '',
            onOtherTextChanged: (_) {},
          ),
        ),
      );

      expect(find.text('티티가 궁금해서'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
      await tester.tap(find.text('심심하거나 외로워서'));
      expect(toggled, [StartReason.boredOrLonely]);
    });
  });

  group('FeedbackResponseSummaryCard', () {
    Widget card({
      PreviousCallRecall? recall,
      Set<AwkwardMoment> moments = const {AwkwardMoment.none},
      int rating = 4,
    }) => FeedbackResponseSummaryCard(
      rating: rating,
      revisitIntention: RevisitIntention.yes,
      previousCallRecall: recall,
      awkwardMoments: moments,
    );

    testWidgets('summaryCard_hidesRecallRowOnFirstCall', (tester) async {
      await pumpAtViewport(tester, _defaultViewport, _wrap(card()));

      expect(find.text('기억한 내용'), findsNothing);
      expect(find.text('오늘 통화 만족도'), findsOneWidget);
      expect(find.text('다시 통화할 의향'), findsOneWidget);
      expect(find.text('어색했던 순간'), findsOneWidget);
    });

    testWidgets('summaryCard_showsRecallRowWhenPresent', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(card(recall: PreviousCallRecall.remembered)),
      );

      expect(find.text('기억한 내용'), findsOneWidget);
      expect(find.text('기억했어'), findsOneWidget);
    });

    testWidgets('summaryCard_listsAllAwkwardMoments', (tester) async {
      await pumpAtViewport(
        tester,
        _defaultViewport,
        _wrap(card(moments: {AwkwardMoment.cut, AwkwardMoment.slow})),
      );

      expect(find.text('말이 끊겼어'), findsOneWidget);
      expect(find.text('답이 늦었어'), findsOneWidget);
    });

    testWidgets('summaryCard_showsRatingStars', (tester) async {
      await pumpAtViewport(tester, _defaultViewport, _wrap(card(rating: 4)));

      expect(_countStars(tester, AppAssets.feedbackStarFilledIcon), 4);
      expect(_countStars(tester, AppAssets.feedbackStarEmptyIcon), 1);
    });
  });

  testWidgets('widgets_renderWithoutOverflowAtNarrowestViewport', (
    tester,
  ) async {
    const narrowContentWidth = 320.0 - 2 * AppLayout.horizontalMargin;
    await pumpAtViewport(
      tester,
      _narrowViewport,
      _wrap(
        Column(
          children: [
            _choiceGroup(
              values: [1, 2, 3, 4, 5],
              columnCount: 3,
              selected: {1},
            ),
            FeedbackStarRating(value: 2, onChanged: (_) {}),
            MemoryNotApplicableCheckRow(isChecked: true, onChanged: (_) {}),
            ScaledQuestionSection(
              title: '티티와 말 주고받는 타이밍은 자연스러웠어?',
              anchorLabels: const ['너무 어색했어', '보통이야', '정말 자연스러웠어'],
              score: 2,
              onScoreChanged: (_) {},
              reasonText: '',
              onReasonChanged: (_) {},
              reasonExample: '예) 끼어들지 않고 잘 들어줘서 편했어.',
            ),
            StartReasonChecklist(
              characterName: '티티',
              selected: const {StartReason.other},
              onToggle: (_) {},
              otherText: '',
              onOtherTextChanged: (_) {},
            ),
            const FeedbackResponseSummaryCard(
              rating: 5,
              revisitIntention: RevisitIntention.yes,
              previousCallRecall: PreviousCallRecall.unsure,
              awkwardMoments: {
                AwkwardMoment.cut,
                AwkwardMoment.slow,
                AwkwardMoment.context,
                AwkwardMoment.repeat,
              },
            ),
          ],
        ),
        width: narrowContentWidth,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
