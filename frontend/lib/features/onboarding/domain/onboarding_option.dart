import 'package:teeq/features/onboarding/domain/onboarding_question.dart';

/// 온보딩 선택지 27개. 선언 순서와 [code]는 BE `OnboardingOption`과 같다.
enum OnboardingOption {
  relationshipCloseFriend(
    OnboardingQuestion.relationship,
    'CLOSE_FRIEND',
    '시시콜콜한 얘기까지 다 하는 절친',
  ),
  relationshipReliableFriend(
    OnboardingQuestion.relationship,
    'RELIABLE_FRIEND',
    '기댈 수 있는 다정한 사이',
  ),
  relationshipSweetPartner(
    OnboardingQuestion.relationship,
    'SWEET_PARTNER',
    '의지할 수 있는 다정한 연인',
  ),
  relationshipLifeMentor(
    OnboardingQuestion.relationship,
    'LIFE_MENTOR',
    '조언을 건네는 인생 선배',
  ),
  personalityMoodMaker(
    OnboardingQuestion.personality,
    'MOOD_MAKER',
    '밝고 에너지 넘치는 분위기 메이커 스타일',
  ),
  personalityPlayfulJoker(
    OnboardingQuestion.personality,
    'PLAYFUL_JOKER',
    '장난기 많고 유쾌한 개구쟁이',
  ),
  personalityCalmWarm(
    OnboardingQuestion.personality,
    'CALM_WARM',
    '차분하고 따뜻한 다정다감형',
  ),
  personalityFreeSpirit(
    OnboardingQuestion.personality,
    'FREE_SPIRIT',
    '엉뚱하고 개성 넘치는 자유로운 영혼',
  ),
  speechStyleCloseFriendCasual(
    OnboardingQuestion.speechStyle,
    'CLOSE_FRIEND_CASUAL',
    '완전 찐친 반말',
  ),
  speechStyleAffectionateCasual(
    OnboardingQuestion.speechStyle,
    'AFFECTIONATE_CASUAL',
    '다정다감 반말',
  ),
  speechStyleGentlePolite(
    OnboardingQuestion.speechStyle,
    'GENTLE_POLITE',
    '부드러운 존댓말',
  ),
  voiceToneHighBright(
    OnboardingQuestion.voiceTone,
    'HIGH_BRIGHT',
    '밝고 경쾌한 하이톤',
  ),
  voiceToneMidNatural(
    OnboardingQuestion.voiceTone,
    'MID_NATURAL',
    '자연스럽고 편안한 미들톤',
  ),
  voiceToneMidLowCalm(
    OnboardingQuestion.voiceTone,
    'MID_LOW_CALM',
    '차분하고 부드러운 중저음',
  ),
  voiceToneLowDeep(OnboardingQuestion.voiceTone, 'LOW_DEEP', '낮고 묵직한 저음'),
  adviceStyleEmpathyOnly(
    OnboardingQuestion.adviceStyle,
    'EMPATHY_ONLY',
    'F 100% 폭풍 공감형',
  ),
  adviceStyleRealisticAdviceOnly(
    OnboardingQuestion.adviceStyle,
    'REALISTIC_ADVICE_ONLY',
    'T 100% 현실 조언형',
  ),
  adviceStyleTakeMySide(
    OnboardingQuestion.adviceStyle,
    'TAKE_MY_SIDE',
    '내 편 들어주는 편파형',
  ),
  adviceStyleBalanced(
    OnboardingQuestion.adviceStyle,
    'BALANCED',
    'T와 F 반반 밸런스형',
  ),
  conversationLeadListener(
    OnboardingQuestion.conversationLead,
    'LISTENER',
    '내 이야기를 충분히 들어주는 경청형',
  ),
  conversationLeadBalanced(
    OnboardingQuestion.conversationLead,
    'BALANCED',
    '서로 자연스럽게 주고받는 밸런스형',
  ),
  conversationLeadLeader(
    OnboardingQuestion.conversationLead,
    'LEADER',
    '먼저 질문하며 대화를 이끄는 리드형',
  ),
  avoidBehaviorRapidQuestions(
    OnboardingQuestion.avoidBehavior,
    'RAPID_QUESTIONS',
    '쉴 틈 없이 질문을 쏟아내는 것',
  ),
  avoidBehaviorUnaskedAdvice(
    OnboardingQuestion.avoidBehavior,
    'UNASKED_ADVICE',
    '묻지도 않았는데 조언부터 하는 것',
  ),
  avoidBehaviorExcessivePositivity(
    OnboardingQuestion.avoidBehavior,
    'EXCESSIVE_POSITIVITY',
    '지나치게 긍정적으로만 반응하는 것',
  ),
  avoidBehaviorRepeatedResponses(
    OnboardingQuestion.avoidBehavior,
    'REPEATED_RESPONSES',
    '같은 말이나 반응을 반복하는 것',
  ),
  avoidBehaviorInterrupting(
    OnboardingQuestion.avoidBehavior,
    'INTERRUPTING',
    '내 말을 중간에 끊는 것',
  );

  const OnboardingOption(this.question, this.codeSuffix, this.label);

  final OnboardingQuestion question;
  final String codeSuffix;
  final String label;

  /// BE enum 이름과 같은 선택지 코드(`<질문 코드>_<접미사>`).
  String get code => '${question.code}_$codeSuffix';
}
