/// 통화가 막히거나 끝난 한도의 종류.
enum CallLimitKind {
  perCall,
  perDay,
  wholeService;

  /// 서버 이름(`PER_CALL` 등)을 한도 종류로 바꾼다. 모르는 값이면 null.
  static CallLimitKind? fromServerName(String? name) => switch (name) {
    'PER_CALL' => CallLimitKind.perCall,
    'PER_DAY' => CallLimitKind.perDay,
    'WHOLE_SERVICE' => CallLimitKind.wholeService,
    _ => null,
  };
}
