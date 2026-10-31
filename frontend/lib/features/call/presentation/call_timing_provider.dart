import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/call/domain/call_timing.dart';

part 'call_timing_provider.g.dart';

/// 통화 화면의 대기 시간 설정(워커 입장 대기, 재연결 카드 유예).
@Riverpod(keepAlive: true)
CallTiming callTiming(Ref ref) => const CallTiming();

/// 통화 경과 시간을 계산할 현재 시각. 테스트에서 가짜 시계로 바꾼다.
@Riverpod(keepAlive: true)
DateTime Function() callClock(Ref ref) => DateTime.now;
