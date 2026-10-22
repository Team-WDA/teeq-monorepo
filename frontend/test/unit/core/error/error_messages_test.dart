import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/error/error_messages.dart';

void main() {
  test('errorMessages_mapBugReportCodes', () {
    for (final code in [
      ErrorCode.bugReportImageInvalid,
      ErrorCode.bugReportImageTooLarge,
      ErrorCode.bugReportImageTooMany,
      ErrorCode.bugReportNotFound,
    ]) {
      expect(code.userMessage, isNot(unknownErrorMessage));
    }
    expect(
      ErrorCode.fromServerName('BUG_REPORT_IMAGE_TOO_MANY'),
      ErrorCode.bugReportImageTooMany,
    );
  });
}
