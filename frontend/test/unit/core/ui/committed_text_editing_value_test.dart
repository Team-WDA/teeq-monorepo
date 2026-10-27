import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/ui/text_field/committed_text_editing_value.dart';

void main() {
  test('조합 중인 구간은 뺀 텍스트를 돌려준다', () {
    const value = TextEditingValue(
      text: '소ㅇ',
      composing: TextRange(start: 1, end: 2),
    );

    expect(value.committedText, '소');
  });

  test('조합이 없으면 text를 그대로 돌려준다', () {
    const value = TextEditingValue(text: '소연');

    expect(value.committedText, '소연');
  });
}
