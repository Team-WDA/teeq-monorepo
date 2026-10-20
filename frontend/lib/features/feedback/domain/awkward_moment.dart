/// 어색했던 순간. [code]는 BE `AwkwardMoment` 상수 이름과 같고, [none]은 다른 선택지와 함께 고를 수 없다.
enum AwkwardMoment {
  cut('CUT'),
  slow('SLOW'),
  context('CONTEXT'),
  repeat('REPEAT'),
  none('NONE');

  const AwkwardMoment(this.code);

  final String code;
}
