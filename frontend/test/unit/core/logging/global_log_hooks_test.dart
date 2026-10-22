import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/logging/app_log_entry.dart';
import 'package:teeq/core/logging/app_log_level.dart';
import 'package:teeq/core/logging/app_logger.dart';
import 'package:teeq/core/logging/global_log_hooks.dart';

void main() {
  late FlutterExceptionHandler? originalFlutterErrorHandler;
  late DebugPrintCallback originalDebugPrint;
  late ErrorCallback? originalPlatformErrorHandler;
  late List<AppLogEntry> entries;
  late List<String?> printedMessages;

  setUp(() {
    originalFlutterErrorHandler = FlutterError.onError;
    originalDebugPrint = debugPrint;
    originalPlatformErrorHandler = PlatformDispatcher.instance.onError;
    entries = [];
    printedMessages = [];
    // 훅이 감쌀 "이전" 핸들러. 테스트 바인딩의 실패 처리기를 피하려고 직접 지정한다.
    FlutterError.onError = (details) {
      // FlutterError.presentError가 에러를 덤프할 때 debugPrint를 쓰는 것을 흉내 낸다.
      debugPrint('에러 덤프 한 줄');
    };
    debugPrint = (message, {wrapWidth}) => printedMessages.add(message);
    PlatformDispatcher.instance.onError = null;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterErrorHandler;
    debugPrint = originalDebugPrint;
    PlatformDispatcher.instance.onError = originalPlatformErrorHandler;
  });

  test('logs a FlutterError once, without its debugPrint dump lines', () {
    installGlobalLogHooks(AppLogger(onEntry: entries.add));

    FlutterError.reportError(FlutterErrorDetails(exception: Exception('boom')));

    final errors = entries.where((e) => e.level == AppLogLevel.error);
    expect(errors, hasLength(1));
    expect(errors.single.name, 'FlutterError');
    expect(errors.single.message, contains('boom'));
    expect(entries.where((e) => e.name == 'debugPrint'), isEmpty);
    expect(printedMessages, ['에러 덤프 한 줄']);
  });

  test('logs debugPrint as a debug entry and still prints', () {
    installGlobalLogHooks(AppLogger(onEntry: entries.add));

    debugPrint('hello');

    expect(entries.single.level, AppLogLevel.debug);
    expect(entries.single.name, 'debugPrint');
    expect(entries.single.message, 'hello');
    expect(printedMessages, ['hello']);
  });

  test('records debugPrint again after a FlutterError was handled', () {
    installGlobalLogHooks(AppLogger(onEntry: entries.add));
    FlutterError.reportError(FlutterErrorDetails(exception: Exception('boom')));
    entries.clear();

    debugPrint('after');

    expect(entries.single.message, 'after');
  });

  test('logs platform errors and leaves default handling to the caller', () {
    installGlobalLogHooks(AppLogger(onEntry: entries.add));

    final handled = PlatformDispatcher.instance.onError!(
      Exception('x'),
      StackTrace.fromString('#0 main'),
    );

    expect(handled, isFalse);
    expect(entries.single.level, AppLogLevel.error);
    expect(entries.single.errorDescription, contains('x'));
    expect(entries.single.stackTraceText, '#0 main');
  });

  test('keeps the answer of a previously installed platform handler', () {
    PlatformDispatcher.instance.onError = (error, stack) => true;
    installGlobalLogHooks(AppLogger(onEntry: entries.add));

    final handled = PlatformDispatcher.instance.onError!(
      Exception('x'),
      StackTrace.empty,
    );

    expect(handled, isTrue);
    expect(entries, hasLength(1));
  });
}
