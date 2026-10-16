package kr.teeq.api.aicharacter.core.constant;

/**
 * AI 캐릭터 입력 규칙과 AI 서버 응답 제약. 제출 요청 검증과 AI 응답 검증이 함께 쓴다.
 */
public final class AiCharacterValidation {

    public static final String NAME_REGEX = "^[가-힣A-Za-z0-9]{2,10}$";
    public static final String NAME_MESSAGE = "캐릭터 이름은 한글, 영문, 숫자만 사용해 2~10자로 입력해 주세요.";

    public static final int PERSONALITY_TAG_COUNT = 3;
    // 마이그레이션의 personality_tag_* 컬럼 길이와 같아야 한다
    public static final int PERSONALITY_TAG_MAX_LENGTH = 50;

    private AiCharacterValidation() {
    }

}
