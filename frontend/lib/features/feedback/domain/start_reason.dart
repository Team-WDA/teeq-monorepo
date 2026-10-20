/// 통화를 시작한 이유. [code]는 BE `StartReason` 상수 이름과 같다.
enum StartReason {
  needToTalk('NEED_TO_TALK'),
  wantToConfide('WANT_TO_CONFIDE'),
  boredOrLonely('BORED_OR_LONELY'),
  curiousAboutCharacter('CURIOUS_ABOUT_CHARACTER'),
  testingService('TESTING_SERVICE'),
  other('OTHER');

  const StartReason(this.code);

  final String code;
}
