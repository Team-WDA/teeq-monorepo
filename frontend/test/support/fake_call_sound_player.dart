import 'package:teeq/features/call/domain/call_sound_player.dart';

/// 호출을 문자열로 기록하는 테스트용 효과음 재생기.
/// 기록 형식: `ringtone`, `connecting:speaker=<bool>`, `stop:fade=<bool>`, `end`.
class FakeCallSoundPlayer implements CallSoundPlayer {
  final List<String> calls = [];

  @override
  Future<void> startRingtone() async {
    calls.add('ringtone');
  }

  @override
  Future<void> startConnectingTone({required bool isSpeakerOn}) async {
    calls.add('connecting:speaker=$isSpeakerOn');
  }

  @override
  Future<void> stopLoopingTone({required bool shouldFadeOut}) async {
    calls.add('stop:fade=$shouldFadeOut');
  }

  @override
  Future<void> playEndTone() async {
    calls.add('end');
  }
}
