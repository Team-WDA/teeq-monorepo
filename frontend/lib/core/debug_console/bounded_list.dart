/// 디버그 콘솔 목록 하나가 보관하는 최대 건수.
const int debugConsoleEntryCapacity = 500;

/// [items] 끝에 [item]을 붙인 새 목록을 돌려준다. [capacity]를 넘으면 가장 오래된 것부터 버린다.
/// 원본은 바꾸지 않고, 돌려주는 목록은 수정할 수 없다.
List<T> appendBounded<T>(
  List<T> items,
  T item, {
  int capacity = debugConsoleEntryCapacity,
}) {
  final appended = [...items, item];
  final overflow = appended.length - capacity;
  return List.unmodifiable(
    overflow > 0 ? appended.sublist(overflow) : appended,
  );
}
