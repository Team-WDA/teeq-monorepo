import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teeq/core/ui/toast/toast_controller.dart';

/// [text]를 클립보드에 복사하고 토스트로 알린다.
Future<void> copyToClipboard(WidgetRef ref, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  ref.read(toastControllerProvider.notifier).show('복사했습니다');
}
