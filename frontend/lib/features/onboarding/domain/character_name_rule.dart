/// 캐릭터 이름 규칙(BE와 같다): 한글만, 2~10자.
final RegExp characterNamePattern = RegExp(r'^[가-힣]{2,10}$');

/// 입력 단계에서 허용하는 한 글자. IME 조합 중인 호환 자모도 막히지 않게 자모를 포함한다.
final RegExp characterNameInputCharacterPattern = RegExp(r'[가-힣ㄱ-ㅣ]');

const int characterNameMaximumLength = 10;
