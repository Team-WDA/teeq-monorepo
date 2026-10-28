import 'package:flutter/services.dart';

extension CommittedTextEditingValue on TextEditingValue {
  /// IME가 조합 중인 글자(예: 'ㅅ')는 빼고 확정된 입력만 돌려준다.
  /// 조합 중인 자모를 그대로 검사하면 음절마다 문자 오류가 깜빡인다.
  String get committedText {
    if (!composing.isValid || composing.isCollapsed) {
      return text;
    }
    return composing.textBefore(text) + composing.textAfter(text);
  }
}
