/// 지난 통화 기억 여부. [code]는 BE `PreviousCallRecall` 상수 이름과 같다.
enum PreviousCallRecall {
  remembered('REMEMBERED'),
  unsure('UNSURE'),
  no('NO');

  const PreviousCallRecall(this.code);

  final String code;
}
