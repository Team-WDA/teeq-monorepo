import 'package:teeq/core/error/error_code.dart';

/// 알 수 없는 문제에 쓰는 공통 사용자 문구.
const String unknownErrorMessage = '알 수 없는 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';

/// 네트워크 단절·타임아웃에 쓰는 사용자 문구.
const String networkErrorMessage = '네트워크 연결을 확인하고 다시 시도해 주세요.';

/// [ErrorCode]를 사용자에게 보여 줄 한국어 문구로 바꾸는 중앙 매핑.
/// 서버가 보낸 `errorMessage`는 어디에서도 표시하지 않는다.
extension ErrorCodeUserMessage on ErrorCode {
  String get userMessage => switch (this) {
    ErrorCode.invalidRequest => '요청을 처리할 수 없어요. 입력한 내용을 다시 확인해 주세요.',
    ErrorCode.malformedRequestBody => '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.resourceNotFound => '요청한 정보를 찾을 수 없어요.',
    ErrorCode.methodNotAllowed => '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.unsupportedMediaType => '지원하지 않는 형식이에요.',
    ErrorCode.stateConflict => '지금은 요청을 처리할 수 없어요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.internalServerError => '문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.unauthenticated => '다시 로그인해 주세요.',
    ErrorCode.expiredToken => '다시 로그인해 주세요.',
    ErrorCode.invalidRefreshToken => '다시 로그인해 주세요.',
    ErrorCode.invalidCredentials => '이메일 또는 비밀번호가 올바르지 않아요.',
    ErrorCode.accessDenied => '접근 권한이 없어요.',
    ErrorCode.duplicateEmail => '이미 사용 중인 이메일이에요.',
    ErrorCode.duplicateNickname => '이미 사용 중인 닉네임이에요.',
    ErrorCode.invalidCurrentPassword => '현재 비밀번호가 올바르지 않아요.',
    ErrorCode.memberNotFound => '회원 정보를 찾을 수 없어요.',
    ErrorCode.socialTokenInvalid => '소셜 로그인에 실패했어요. 다시 시도해 주세요.',
    ErrorCode.socialServerUnavailable =>
      '소셜 로그인 서버와 연결할 수 없어요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.socialSignupRequired => '가입에 필요한 정보가 더 필요해요.',
    ErrorCode.loginMethodMismatch => '가입한 로그인 방식으로 로그인해 주세요.',
    ErrorCode.callLimitInsufficient => '오늘 쓸 수 있는 통화 시간이 부족해요.',
    ErrorCode.callServiceLimitExceeded => '지금은 통화를 이용할 수 없어요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.callBonusNotFound => '추가 통화 시간을 찾을 수 없어요.',
    ErrorCode.callAlreadyInProgress => '이미 진행 중인 통화가 있어요.',
    ErrorCode.aiServerUnavailable => '지금은 연결이 원활하지 않아요. 잠시 후 다시 시도해 주세요.',
    ErrorCode.callSessionNotFound => '통화 정보를 찾을 수 없어요.',
    ErrorCode.callNotFeedbackable => '의견을 남길 수 없는 통화예요.',
    ErrorCode.feedbackAlreadySubmitted => '이미 의견을 보냈어요.',
    ErrorCode.requiredFeedbackNotSubmitted => '먼저 통화 의견을 남겨 주세요.',
    ErrorCode.detailedFeedbackNotInvited => '상세 의견 대상이 아닌 통화예요.',
    ErrorCode.invalidFeedbackAnswer => '답변을 다시 확인해 주세요.',
    ErrorCode.onboardingAnswerIncomplete => '모든 질문에 답해 주세요.',
    ErrorCode.onboardingAnswerDuplicated => '답변을 다시 확인해 주세요.',
    ErrorCode.invalidOnboardingOption => '선택한 항목을 다시 확인해 주세요.',
    ErrorCode.aiCharacterNotFound => '캐릭터를 찾을 수 없어요.',
    ErrorCode.profileImageInvalid => 'JPEG, PNG, WebP 이미지만 사진으로 쓸 수 있어요.',
    ErrorCode.profileImageTooLarge => '사진은 5MB 이하만 올릴 수 있어요.',
    ErrorCode.settingConfigNotFound => '설정을 찾을 수 없어요.',
    ErrorCode.invalidSettingValue => '설정 값을 다시 확인해 주세요.',
    ErrorCode.unknown => unknownErrorMessage,
  };
}
