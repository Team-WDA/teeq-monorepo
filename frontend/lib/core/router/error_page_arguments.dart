/// 오류 페이지로 넘기는 값.
class ErrorPageArguments {
  const ErrorPageArguments({
    required this.message,
    required this.retryLocation,
  });

  /// 사용자에게 보여 줄 문구.
  final String message;

  /// "다시 시도"를 누르면 돌아갈 위치.
  final String retryLocation;
}
