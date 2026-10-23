import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/features/auth/domain/auth_credential_provider.dart';

part 'firebase_auth_credential_provider.g.dart';

@Riverpod(keepAlive: true)
AuthCredentialProvider authCredentialProvider(Ref ref) =>
    FirebaseAuthCredentialProvider();

/// Firebase Authentication과 `google_sign_in`으로 로그인 자격 증명을 만드는 구현.
/// Apple은 Firebase가 네이티브 시트를 직접 열고, Google은 `google_sign_in`으로 받은 토큰을 Firebase에 넘긴다.
/// 이메일·비밀번호는 Firebase가 직접 처리하며, 그 실패(`FirebaseAuthException`)는 앱 예외로 바꿔 던진다.
final class FirebaseAuthCredentialProvider implements AuthCredentialProvider {
  FirebaseAuthCredentialProvider({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuthOverride = firebaseAuth,
       _googleSignInOverride = googleSignIn;

  /// Firebase가 초기화되기 전에 만들어도 안전하도록 쓰는 시점에 인스턴스를 가져온다.
  final FirebaseAuth? _firebaseAuthOverride;
  final GoogleSignIn? _googleSignInOverride;

  bool _isGoogleSignInInitialized = false;

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInOverride ?? GoogleSignIn.instance;

  /// Firebase가 취소로 알리는 오류 코드. iOS 네이티브는 `canceled`, 웹 기반 흐름은 `web-context-canceled`.
  static const Set<String> _cancellationCodes = {
    'canceled',
    'web-context-canceled',
  };

  /// 서버가 이메일을 요구하므로 이메일 범위를 요청한다.
  static AppleAuthProvider _createAppleProvider() =>
      AppleAuthProvider()..addScope('email');

  /// 사용자가 취소해서 난 오류인지 판정한다.
  static bool isCancellation(FirebaseAuthException error) =>
      _cancellationCodes.contains(error.code);

  @override
  Future<String> signInWithApple() async {
    final UserCredential credential;
    try {
      credential = await _firebaseAuth.signInWithProvider(
        _createAppleProvider(),
      );
    } on FirebaseAuthException catch (error) {
      if (isCancellation(error)) {
        throw const SignInCancelledException();
      }
      rethrow;
    }
    return _idTokenOf(credential.user);
  }

  @override
  Future<String> signInWithGoogle() async {
    await _initializeGoogleSignInOnce();
    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelledException();
      }
      rethrow;
    }
    final googleIdToken = account.authentication.idToken;
    if (googleIdToken == null) {
      throw const UnexpectedException('Google ID token 없음');
    }
    final credential = await _firebaseAuth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: googleIdToken),
    );
    return _idTokenOf(credential.user);
  }

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _guardEmailAuth(
      () => _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    return _idTokenOf(credential.user);
  }

  @override
  Future<String> createEmailAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _guardEmailAuth(
      () => _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
    return _idTokenOf(credential.user);
  }

  @override
  Future<void> changeEmailPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final credential = await _guardEmailAuth(
      () => _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: currentPassword,
      ),
      isCurrentPasswordCheck: true,
    );
    final user = credential.user;
    if (user == null) {
      throw const UnexpectedException('Firebase 사용자 없음');
    }
    await _guardEmailAuth(() => user.updatePassword(newPassword));
  }

  /// Firebase 오류를 앱 예외로 바꿔 던진다. [isCurrentPasswordCheck]이면 자격 증명 오류를
  /// 현재 비밀번호 오류로 바꾼다(비밀번호 변경 화면이 인라인으로 보여 준다).
  Future<T> _guardEmailAuth<T>(
    Future<T> Function() action, {
    bool isCurrentPasswordCheck = false,
  }) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw mapEmailAuthException(
        error,
        isCurrentPasswordCheck: isCurrentPasswordCheck,
      );
    }
  }

  /// 이메일 인증 관련 Firebase 오류 코드를 앱 예외로 바꾼다.
  /// 이메일 열거 방지가 켜져 있으면 없는 이메일과 틀린 비밀번호가 모두 `invalid-credential`로 온다.
  /// 그 밖의 코드(`weak-password`, `user-disabled` 등)는 일반 오류로 처리한다.
  static AppException mapEmailAuthException(
    FirebaseAuthException error, {
    bool isCurrentPasswordCheck = false,
  }) => switch (error.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-email' =>
      isCurrentPasswordCheck
          ? InvalidCurrentPasswordException(error)
          : InvalidCredentialsException(error),
    'email-already-in-use' => EmailAlreadyInUseException(error),
    'too-many-requests' => TooManyAttemptsException(error),
    'network-request-failed' => const NetworkException(
      NetworkFailureKind.connection,
    ),
    _ => UnexpectedException(error),
  };

  @override
  Future<String> fetchLatestIdToken() => _idTokenOf(_firebaseAuth.currentUser);

  @override
  Future<void> revokeAppleConnection() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AppleConnectionRevokeFailedException('Firebase 사용자 없음');
    }
    final UserCredential credential;
    try {
      credential = await user.reauthenticateWithProvider(
        _createAppleProvider(),
      );
    } on FirebaseAuthException catch (error) {
      if (isCancellation(error)) {
        throw const SignInCancelledException();
      }
      // 다른 Apple 계정으로 재인증한 경우(user-mismatch)도 여기서 실패로 본다.
      throw AppleConnectionRevokeFailedException(error);
    } on Object catch (error) {
      throw AppleConnectionRevokeFailedException(error);
    }
    final authorizationCode = credential.additionalUserInfo?.authorizationCode;
    if (authorizationCode == null || authorizationCode.isEmpty) {
      throw const AppleConnectionRevokeFailedException('authorization code 없음');
    }
    try {
      await _firebaseAuth.revokeTokenWithAuthorizationCode(authorizationCode);
    } on Object catch (error) {
      throw AppleConnectionRevokeFailedException(error);
    }
  }

  @override
  Future<void> deleteCreatedAccount() async {
    await _firebaseAuth.currentUser?.delete();
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } finally {
      await _signOutOfGoogle();
    }
  }

  Future<void> _signOutOfGoogle() async {
    await _initializeGoogleSignInOnce();
    await _googleSignIn.signOut();
  }

  /// `google_sign_in` 7은 로그인 전에 한 번 초기화해야 한다. 클라이언트 ID는 네이티브 설정 파일에서 읽는다.
  Future<void> _initializeGoogleSignInOnce() async {
    if (_isGoogleSignInInitialized) {
      return;
    }
    await _googleSignIn.initialize();
    _isGoogleSignInInitialized = true;
  }

  Future<String> _idTokenOf(User? user) async {
    final idToken = await user?.getIdToken();
    if (idToken == null) {
      throw const UnexpectedException('Firebase ID token 없음');
    }
    return idToken;
  }
}
