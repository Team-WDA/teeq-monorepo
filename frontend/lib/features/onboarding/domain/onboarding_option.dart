/// 온보딩 선택지. [code]는 BE enum 이름과 같은 전체 코드(`<질문 코드>_<접미사>`)이며 같음 비교의 기준이다.
final class OnboardingOption {
  const OnboardingOption({required this.code, required this.label});

  final String code;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is OnboardingOption && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
