/// 질문 하나의 화면 문구.
final class OnboardingQuestionCopy {
  const OnboardingQuestionCopy({
    required this.title,
    required this.description,
  });

  final String title;

  /// 제목 아래 부제(선택 방식 표기 제외).
  final String description;
}

/// 온보딩 질문·선택지 문구 사전. 질문 구조(순서, 선택 수, 선택지 목록)는 서버가 내려주고
/// 문구는 FE가 코드로 찾아 붙인다. 키는 BE enum 이름과 같은 전체 코드다.
abstract final class OnboardingCopy {
  static const Map<String, OnboardingQuestionCopy> questions = {
    'RELATIONSHIP': OnboardingQuestionCopy(
      title: '우리,\n어떤 사이로 지낼까?',
      description: '너에게 가장 편안한 관계를 골라줘.',
    ),
    'PERSONALITY': OnboardingQuestionCopy(
      title: '너는 어떤\n성격이 좋아?',
      description: '마음에 드는 성격을 골라줘.',
    ),
    'SPEECH_STYLE': OnboardingQuestionCopy(
      title: '어떤 말투가\n제일 좋아?',
      description: '같은 말도 어떻게 하느냐가 중요하니까.',
    ),
    'VOICE_TONE': OnboardingQuestionCopy(
      title: '어떤 목소리로\n들려줄까?',
      description: '오래 들어도 편안한 목소리를 골라줘.',
    ),
    'ADVICE_STYLE': OnboardingQuestionCopy(
      title: '고민 상담할 때,\nT가 좋아? F가 좋아?',
      description: '네가 속상한 일을 털어놓는다면?',
    ),
    'CONVERSATION_LEAD': OnboardingQuestionCopy(
      title: '대화할 땐\n누가 리드하는 게 좋아?',
      description: '우리의 대화 텐션을 맞춰보자.',
    ),
    'AVOID_BEHAVIOR': OnboardingQuestionCopy(
      title: '대화할 때,\n이것만은 피했으면 해!',
      description: '불편하게 느껴지는 대화 방식을 알려줘.',
    ),
  };

  static const Map<String, String> optionLabels = {
    'RELATIONSHIP_CLOSE_FRIEND': '시시콜콜한 얘기까지 다 하는 절친',
    'RELATIONSHIP_RELIABLE_FRIEND': '기댈 수 있는 다정한 사이',
    'RELATIONSHIP_SWEET_PARTNER': '의지할 수 있는 다정한 연인',
    'RELATIONSHIP_LIFE_MENTOR': '조언을 건네는 인생 선배',
    'PERSONALITY_MOOD_MAKER': '밝고 에너지 넘치는 분위기 메이커 스타일',
    'PERSONALITY_PLAYFUL_JOKER': '장난기 많고 유쾌한 개구쟁이',
    'PERSONALITY_CALM_WARM': '차분하고 따뜻한 다정다감형',
    'PERSONALITY_FREE_SPIRIT': '엉뚱하고 개성 넘치는 자유로운 영혼',
    'SPEECH_STYLE_CLOSE_FRIEND_CASUAL': '완전 찐친 반말',
    'SPEECH_STYLE_AFFECTIONATE_CASUAL': '다정다감 반말',
    'SPEECH_STYLE_GENTLE_POLITE': '부드러운 존댓말',
    'VOICE_TONE_HIGH_BRIGHT': '밝고 경쾌한 하이톤',
    'VOICE_TONE_MID_NATURAL': '자연스럽고 편안한 미들톤',
    'VOICE_TONE_MID_LOW_CALM': '차분하고 부드러운 중저음',
    'VOICE_TONE_LOW_DEEP': '낮고 묵직한 저음',
    'ADVICE_STYLE_EMPATHY_ONLY': 'F 100% 폭풍 공감형',
    'ADVICE_STYLE_REALISTIC_ADVICE_ONLY': 'T 100% 현실 조언형',
    'ADVICE_STYLE_TAKE_MY_SIDE': '내 편 들어주는 편파형',
    'ADVICE_STYLE_BALANCED': 'T와 F 반반 밸런스형',
    'CONVERSATION_LEAD_LISTENER': '내 이야기를 충분히 들어주는 경청형',
    'CONVERSATION_LEAD_BALANCED': '서로 자연스럽게 주고받는 밸런스형',
    'CONVERSATION_LEAD_LEADER': '먼저 질문하며 대화를 이끄는 리드형',
    'AVOID_BEHAVIOR_RAPID_QUESTIONS': '쉴 틈 없이 질문을 쏟아내는 것',
    'AVOID_BEHAVIOR_UNASKED_ADVICE': '묻지도 않았는데 조언부터 하는 것',
    'AVOID_BEHAVIOR_EXCESSIVE_POSITIVITY': '지나치게 긍정적으로만 반응하는 것',
    'AVOID_BEHAVIOR_REPEATED_RESPONSES': '같은 말이나 반응을 반복하는 것',
    'AVOID_BEHAVIOR_INTERRUPTING': '내 말을 중간에 끊는 것',
  };
}
