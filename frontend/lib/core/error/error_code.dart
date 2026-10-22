/// 서버 `ErrorCode.java` 상수와 1:1로 대응하는 에러 코드.
/// 서버 상수 이름은 [serverName]에 그대로 두고, 클라이언트 전용 [unknown]을 추가로 가진다.
enum ErrorCode {
  // 공통
  invalidRequest('INVALID_REQUEST'),
  malformedRequestBody('MALFORMED_REQUEST_BODY'),
  resourceNotFound('RESOURCE_NOT_FOUND'),
  methodNotAllowed('METHOD_NOT_ALLOWED'),
  unsupportedMediaType('UNSUPPORTED_MEDIA_TYPE'),
  stateConflict('STATE_CONFLICT'),
  internalServerError('INTERNAL_SERVER_ERROR'),

  // 인증과 계정
  unauthenticated('UNAUTHENTICATED'),
  expiredToken('EXPIRED_TOKEN'),
  invalidCredentials('INVALID_CREDENTIALS'),
  invalidRefreshToken('INVALID_REFRESH_TOKEN'),
  accessDenied('ACCESS_DENIED'),
  duplicateEmail('DUPLICATE_EMAIL'),
  duplicateNickname('DUPLICATE_NICKNAME'),
  invalidCurrentPassword('INVALID_CURRENT_PASSWORD'),
  memberNotFound('MEMBER_NOT_FOUND'),
  adminNotFound('ADMIN_NOT_FOUND'),
  duplicateAdminUsername('DUPLICATE_ADMIN_USERNAME'),
  lastSuperAdminProtected('LAST_SUPER_ADMIN_PROTECTED'),
  adminSelfChangeForbidden('ADMIN_SELF_CHANGE_FORBIDDEN'),
  socialTokenInvalid('SOCIAL_TOKEN_INVALID'),
  socialServerUnavailable('SOCIAL_SERVER_UNAVAILABLE'),
  signupNotCompleted('SIGNUP_NOT_COMPLETED'),
  loginMethodMismatch('LOGIN_METHOD_MISMATCH'),

  // 통화
  callLimitInsufficient('CALL_LIMIT_INSUFFICIENT'),
  callServiceLimitExceeded('CALL_SERVICE_LIMIT_EXCEEDED'),
  callBonusNotFound('CALL_BONUS_NOT_FOUND'),
  callAlreadyInProgress('CALL_ALREADY_IN_PROGRESS'),
  aiServerUnavailable('AI_SERVER_UNAVAILABLE'),
  callSessionNotFound('CALL_SESSION_NOT_FOUND'),

  // 피드백
  callNotFeedbackable('CALL_NOT_FEEDBACKABLE'),
  feedbackAlreadySubmitted('FEEDBACK_ALREADY_SUBMITTED'),
  requiredFeedbackNotSubmitted('REQUIRED_FEEDBACK_NOT_SUBMITTED'),
  detailedFeedbackNotInvited('DETAILED_FEEDBACK_NOT_INVITED'),
  invalidFeedbackAnswer('INVALID_FEEDBACK_ANSWER'),

  // 온보딩
  onboardingAnswerIncomplete('ONBOARDING_ANSWER_INCOMPLETE'),
  onboardingAnswerDuplicated('ONBOARDING_ANSWER_DUPLICATED'),
  invalidOnboardingOption('INVALID_ONBOARDING_OPTION'),

  // AI 캐릭터
  aiCharacterNotFound('AI_CHARACTER_NOT_FOUND'),

  // 프로필 사진
  profileImageInvalid('PROFILE_IMAGE_INVALID'),
  profileImageTooLarge('PROFILE_IMAGE_TOO_LARGE'),

  // 동적 설정
  settingConfigNotFound('SETTING_CONFIG_NOT_FOUND'),
  invalidSettingValue('INVALID_SETTING_VALUE'),

  // 클라이언트 전용: 서버가 보내지 않았거나 모르는 코드
  unknown('UNKNOWN');

  const ErrorCode(this.serverName);

  /// 서버 enum 상수 이름 원본.
  final String serverName;

  /// 서버가 보낸 문자열을 코드로 바꾼다. null이거나 모르는 이름이면 [unknown].
  static ErrorCode fromServerName(String? serverName) {
    for (final code in values) {
      if (code.serverName == serverName) {
        return code;
      }
    }
    return unknown;
  }
}
