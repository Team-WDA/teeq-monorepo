import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/features/onboarding/domain/onboarding_question_screen_name.dart';

void main() {
  test('질문 인덱스 0은 question-1이다', () {
    expect(onboardingQuestionScreenName(0), '/onboarding/question-1');
  });

  test('질문 인덱스 6은 question-7이다', () {
    expect(onboardingQuestionScreenName(6), '/onboarding/question-7');
  });
}
