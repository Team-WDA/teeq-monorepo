import 'package:teeq/core/text/korean_particle.dart';
import 'package:teeq/features/feedback/domain/awkward_moment.dart';
import 'package:teeq/features/feedback/domain/previous_call_recall.dart';
import 'package:teeq/features/feedback/domain/revisit_intention.dart';
import 'package:teeq/features/feedback/domain/start_reason.dart';

/// 재통화 의향 선택지의 화면 문구.
extension RevisitIntentionLabel on RevisitIntention {
  String get label => switch (this) {
    RevisitIntention.no => '아니',
    RevisitIntention.neutral => '그냥 그래',
    RevisitIntention.yes => '응, 또 할래',
  };
}

/// 지난 통화 기억 여부 선택지의 화면 문구.
extension PreviousCallRecallLabel on PreviousCallRecall {
  String get label => switch (this) {
    PreviousCallRecall.remembered => '기억했어',
    PreviousCallRecall.unsure => '잘 모르겠어',
    PreviousCallRecall.no => '기억 못 했어',
  };
}

/// 어색했던 순간 선택지의 화면 문구.
extension AwkwardMomentLabel on AwkwardMoment {
  String get label => switch (this) {
    AwkwardMoment.cut => '말이 끊겼어',
    AwkwardMoment.slow => '답이 늦었어',
    AwkwardMoment.context => '맥락이 안 맞았어',
    AwkwardMoment.repeat => '같은 말을 반복했어',
    AwkwardMoment.none => '없었어',
  };
}

/// 통화 시작 이유 선택지의 화면 문구. 캐릭터 이름이 들어가는 문구가 있어 이름을 받는다.
extension StartReasonLabel on StartReason {
  String labelFor(String characterName) => switch (this) {
    StartReason.needToTalk => '누군가와 이야기하고 싶어서',
    StartReason.wantToConfide => '고민을 털어놓고 싶어서',
    StartReason.boredOrLonely => '심심하거나 외로워서',
    StartReason.curiousAboutCharacter =>
      '${withSubjectParticle(characterName)} 궁금해서',
    StartReason.testingService => '서비스를 테스트하려고',
    StartReason.other => '기타',
  };
}
