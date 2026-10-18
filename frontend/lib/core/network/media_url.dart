/// API 기준 주소와 서버가 내려준 미디어 경로를 슬래시 하나로 이어 붙인다.
String mediaUrl(String apiBaseUrl, String path) {
  if (apiBaseUrl.isEmpty) {
    throw ArgumentError.value(apiBaseUrl, 'apiBaseUrl', '비어 있을 수 없다');
  }
  final baseWithoutTrailingSlash = apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;
  final pathWithoutLeadingSlash = path.startsWith('/')
      ? path.substring(1)
      : path;
  return '$baseWithoutTrailingSlash/$pathWithoutLeadingSlash';
}
