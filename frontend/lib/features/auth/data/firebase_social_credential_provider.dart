import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/features/auth/domain/social_credential_provider.dart';

part 'firebase_social_credential_provider.g.dart';

@Riverpod(keepAlive: true)
SocialCredentialProvider socialCredentialProvider(Ref ref) =>
    FirebaseSocialCredentialProvider();

/// Firebase Authentication과 `google_sign_in`으로 소셜 로그인 자격 증명을 만드는 구현.
/// Apple은 Firebase가 네이티브 시트를 직접 열고, Google은 `google_sign_in`으로 받은 토큰을 Firebase에 넘긴다.
final class FirebaseSocialCredentialProvider
    implements SocialCredentialProvider {
  FirebaseSocialCredentialProvider({
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
        throw const SocialSignInCancelledException();
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
        throw const SocialSignInCancelledException();
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
        throw const SocialSignInCancelledException();
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
  Future<void> deleteFirebaseUser() async {
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
