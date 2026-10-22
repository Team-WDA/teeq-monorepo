import 'package:teeq/features/app_update/domain/app_update_requirement.dart';
import 'package:teeq/features/app_update/presentation/app_update_controller.dart';

/// 테스트에서 업데이트 필요 여부를 처음부터 정하는 가짜 컨트롤러. 네트워크를 부르지 않는다.
/// [requirement]가 있으면 상태가 그 값이고, `check()`는 요구사항이 있을 때만 true를 돌려준다.
/// 호출 시각은 [onCheck]로 남길 수 있다.
class FakeAppUpdateController extends AppUpdateController {
  FakeAppUpdateController({
    this.requirement,
    this.onCheck,
    this.initialRequirement,
  });

  /// `check()`가 true를 돌려주며 상태에 채울 요구사항. null이면 `check()`는 false.
  final AppUpdateRequirement? requirement;
  final void Function()? onCheck;

  /// 처음부터 채워 둘 상태. 화면 테스트에서 업데이트 필요 상태로 시작할 때 쓴다.
  final AppUpdateRequirement? initialRequirement;

  /// `check()`가 불린 횟수.
  int checkCount = 0;

  @override
  AppUpdateRequirement? build() => initialRequirement;

  @override
  Future<bool> check() async {
    checkCount++;
    onCheck?.call();
    final result = requirement;
    if (result == null) {
      return false;
    }
    state = result;
    return true;
  }
}
