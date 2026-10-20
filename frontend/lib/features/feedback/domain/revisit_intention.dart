/// 재통화 의향. [code]는 BE `RevisitIntention` 상수 이름과 같다.
enum RevisitIntention {
  no('NO'),
  neutral('NEUTRAL'),
  yes('YES');

  const RevisitIntention(this.code);

  final String code;
}
