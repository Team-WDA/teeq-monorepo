const int _firstHangulSyllable = 0xAC00; // '가'
const int _lastHangulSyllable = 0xD7A3; // '힣'
const int _finalConsonantCount = 28;

/// 이름 뒤에 서술격 조사를 붙인다. 받침이 있으면 "이야", 없으면 "야".
String withCopulaParticle(String text) =>
    text + (_hasFinalConsonant(text) ? '이야' : '야');

/// 이름 뒤에 주격 조사를 붙인다. 받침이 있으면 "이", 없으면 "가".
String withSubjectParticle(String text) =>
    text + (_hasFinalConsonant(text) ? '이' : '가');

/// 마지막 글자가 받침이 있는 한글 음절인지 판별한다. 한글이 아닌 글자는 받침 없음으로 본다.
bool _hasFinalConsonant(String text) {
  if (text.isEmpty) {
    throw ArgumentError.value(text, 'text', '빈 문자열에는 조사를 붙일 수 없다');
  }
  final lastCodeUnit = text.codeUnitAt(text.length - 1);
  if (lastCodeUnit < _firstHangulSyllable ||
      lastCodeUnit > _lastHangulSyllable) {
    return false;
  }
  return (lastCodeUnit - _firstHangulSyllable) % _finalConsonantCount != 0;
}
