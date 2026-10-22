import 'package:flutter/services.dart';
import 'package:teeq/features/feedback/domain/feedback_input_limits.dart';

/// 입력을 UTF-16 코드 유닛 [maxLength]개까지만 남기는 포맷터.
///
/// Flutter 기본 `maxLength`는 글자(grapheme) 단위로 세어 이모지가 많으면 BE의 `@Size`(자바 `char`)를
/// 넘길 수 있으므로 `String.length` 기준으로 자른다. 잘라내는 규칙은 피드백 입력과 같다.
class Utf16LengthLimitingFormatter extends TextInputFormatter {
  const Utf16LengthLimitingFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final limited = FeedbackInputLimits.truncate(newValue.text, maxLength);
    if (limited == newValue.text) {
      return newValue;
    }
    return TextEditingValue(
      text: limited,
      selection: TextSelection.collapsed(
        offset: newValue.selection.extentOffset.clamp(0, limited.length),
      ),
    );
  }
}
