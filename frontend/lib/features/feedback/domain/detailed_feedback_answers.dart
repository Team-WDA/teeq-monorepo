import 'package:teeq/features/feedback/domain/detailed_feedback_question.dart';
import 'package:teeq/features/feedback/domain/detailed_feedback_submission.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';

/// 상세 피드백에서 사용자가 고른 응답. 불변이며 값으로 비교한다.
final class DetailedFeedbackAnswers {
  const DetailedFeedbackAnswers._(
    this._scores,
    this._reasons,
    this._startReasons, {
    required this.memoryNotApplicable,
    required this.freeText,
    required this.startReasonOtherText,
  });

  const DetailedFeedbackAnswers.empty()
    : _scores = const {},
      _reasons = const {},
      memoryNotApplicable = false,
      freeText = '',
      _startReasons = const {},
      startReasonOtherText = '';

  static const int minimumScore = 1;
  static const int maximumScore = 5;

  final Map<DetailedFeedbackQuestion, int> _scores;
  final Map<DetailedFeedbackQuestion, String> _reasons;
  final bool memoryNotApplicable;
  final String freeText;
  final Set<StartReason> _startReasons;
  final String startReasonOtherText;

  Map<DetailedFeedbackQuestion, int> get scores => Map.unmodifiable(_scores);

  Map<DetailedFeedbackQuestion, String> get reasons =>
      Map.unmodifiable(_reasons);

  Set<StartReason> get startReasons => Set.unmodifiable(_startReasons);

  bool get isStartReasonOtherTextEnabled =>
      _startReasons.contains(StartReason.other);

  /// 기억 문항을 제외하지 않았으면 기억 점수가 필요하다.
  bool get isMemoryScoreRequired => !memoryNotApplicable;

  bool get isComplete =>
      DetailedFeedbackQuestion.values.every(_isScoreSatisfied) &&
      _startReasons.isNotEmpty;

  /// 1~5 밖이면 [ArgumentError]를 던진다. 제외된 기억 문항의 점수는 무시한다.
  DetailedFeedbackAnswers withScore(
    DetailedFeedbackQuestion question,
    int score,
  ) {
    if (score < minimumScore || score > maximumScore) {
      throw ArgumentError.value(
        score,
        'score',
        '$minimumScore~$maximumScore 사이여야 합니다.',
      );
    }
    if (_isExcludedMemory(question)) {
      return this;
    }
    return _copyWith(scores: {..._scores, question: score});
  }

  /// 글자 수 상한(UTF-16 코드 유닛 기준)을 넘는 부분은 잘라서 저장한다. 제외된 기억 문항의 이유는 무시한다.
  DetailedFeedbackAnswers withReason(
    DetailedFeedbackQuestion question,
    String reason,
  ) {
    if (_isExcludedMemory(question)) {
      return this;
    }
    return _copyWith(
      reasons: {
        ..._reasons,
        question: FeedbackInputLimits.truncate(
          reason,
          FeedbackInputLimits.reasonMaxLength,
        ),
      },
    );
  }

  /// true이면 기억 점수와 이유를 지운다. 다시 false로 풀면 점수를 새로 골라야 한다.
  DetailedFeedbackAnswers withMemoryNotApplicable(bool notApplicable) {
    if (!notApplicable) {
      return _copyWith(memoryNotApplicable: false);
    }
    return _copyWith(
      scores: {..._scores}..remove(DetailedFeedbackQuestion.memory),
      reasons: {..._reasons}..remove(DetailedFeedbackQuestion.memory),
      memoryNotApplicable: true,
    );
  }

  DetailedFeedbackAnswers withFreeText(String text) => _copyWith(
    freeText: FeedbackInputLimits.truncate(
      text,
      FeedbackInputLimits.freeTextMaxLength,
    ),
  );

  /// 있으면 해제하고 없으면 추가한다. [StartReason.other]를 해제하면 기타 텍스트를 지운다.
  DetailedFeedbackAnswers toggleStartReason(StartReason reason) {
    if (!_startReasons.contains(reason)) {
      return _copyWith(startReasons: {..._startReasons, reason});
    }
    return _copyWith(
      startReasons: {..._startReasons}..remove(reason),
      startReasonOtherText: reason == StartReason.other
          ? ''
          : startReasonOtherText,
    );
  }

  /// [StartReason.other]가 선택되지 않았으면 무시한다.
  DetailedFeedbackAnswers withStartReasonOtherText(String text) {
    if (!isStartReasonOtherTextEnabled) {
      return this;
    }
    return _copyWith(
      startReasonOtherText: FeedbackInputLimits.truncate(
        text,
        FeedbackInputLimits.startReasonOtherTextMaxLength,
      ),
    );
  }

  /// 미완성이면 null. 공백뿐인 텍스트는 제외하고 나머지는 trim한 값을 담는다.
  DetailedFeedbackSubmission? toSubmission() {
    if (!isComplete) {
      return null;
    }
    final trimmedReasons = <DetailedFeedbackQuestion, String>{};
    for (final question in DetailedFeedbackQuestion.values) {
      final reason = _reasons[question]?.trim();
      if (reason != null && reason.isNotEmpty) {
        trimmedReasons[question] = reason;
      }
    }
    return DetailedFeedbackSubmission(
      scores: Map.of(_scores),
      reasons: trimmedReasons,
      memoryNotApplicable: memoryNotApplicable,
      freeText: _trimmedOrNull(freeText),
      startReasons: [
        for (final reason in StartReason.values)
          if (_startReasons.contains(reason)) reason,
      ],
      startReasonOtherText: isStartReasonOtherTextEnabled
          ? _trimmedOrNull(startReasonOtherText)
          : null,
    );
  }

  bool _isExcludedMemory(DetailedFeedbackQuestion question) =>
      question == DetailedFeedbackQuestion.memory && memoryNotApplicable;

  bool _isScoreSatisfied(DetailedFeedbackQuestion question) =>
      _isExcludedMemory(question) || _scores.containsKey(question);

  static String? _trimmedOrNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DetailedFeedbackAnswers _copyWith({
    Map<DetailedFeedbackQuestion, int>? scores,
    Map<DetailedFeedbackQuestion, String>? reasons,
    bool? memoryNotApplicable,
    String? freeText,
    Set<StartReason>? startReasons,
    String? startReasonOtherText,
  }) => DetailedFeedbackAnswers._(
    scores ?? _scores,
    reasons ?? _reasons,
    startReasons ?? _startReasons,
    memoryNotApplicable: memoryNotApplicable ?? this.memoryNotApplicable,
    freeText: freeText ?? this.freeText,
    startReasonOtherText: startReasonOtherText ?? this.startReasonOtherText,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DetailedFeedbackAnswers &&
        other.memoryNotApplicable == memoryNotApplicable &&
        other.freeText == freeText &&
        other.startReasonOtherText == startReasonOtherText &&
        _mapEquals(other._scores, _scores) &&
        _mapEquals(other._reasons, _reasons) &&
        other._startReasons.length == _startReasons.length &&
        other._startReasons.containsAll(_startReasons);
  }

  static bool _mapEquals<V>(
    Map<DetailedFeedbackQuestion, V> first,
    Map<DetailedFeedbackQuestion, V> second,
  ) =>
      first.length == second.length &&
      first.entries.every((entry) => second[entry.key] == entry.value);

  @override
  int get hashCode => Object.hash(
    memoryNotApplicable,
    freeText,
    startReasonOtherText,
    Object.hashAllUnordered(
      _scores.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAllUnordered(
      _reasons.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    Object.hashAllUnordered(_startReasons),
  );
}
