import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/features/auth/domain/signup_draft.dart';

part 'signup_draft_controller.g.dart';

/// 가입 두 단계 사이의 입력값을 보관한다. 가입 화면을 벗어나면 자동으로 사라진다.
@riverpod
class SignupDraftController extends _$SignupDraftController {
  @override
  SignupDraft build() => SignupDraft.empty;

  void save(SignupDraft draft) {
    state = draft;
  }

  /// 가입을 마친 뒤 비밀번호만 비운다. 화면이 이미 사라져 provider가 정리됐다면 아무것도 하지 않는다.
  void clearPassword() {
    if (ref.mounted) {
      state = state.withoutPassword();
    }
  }
}
