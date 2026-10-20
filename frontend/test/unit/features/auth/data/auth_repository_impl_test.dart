import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teeq/core/auth/login_type.dart';
import 'package:teeq/core/auth/token_storage.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:teeq/core/error/app_exception.dart';
import 'package:teeq/core/error/error_code.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/auth/data/auth_repository_impl.dart';
import 'package:teeq/features/auth/domain/auth_repository.dart';
import 'package:teeq/features/auth/domain/profile_image_file.dart';

import '../../../../support/fake_token_storage.dart';
import '../../../../support/scripted_http_client_adapter.dart';

const _memberJson = {
  'memberId': 'member-1',
  'email': 'user@example.com',
  'nickname': '티큐',
  'hasAiCharacter': false,
  'loginType': 'EMAIL',
  'profileImageUrl': null,
};

const _authJson = {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'memberId': 'member-1',
  'nickname': '티큐',
  'hasAiCharacter': false,
  'loginType': 'EMAIL',
  'profileImageUrl': null,
};

({AuthRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      appConfigProvider.overrideWithValue(
        const AppConfig(
          apiBaseUrl: 'https://api.example.test',
          appleServiceId: 'kr.co.teeq.app.service',
          appleRedirectUri: 'https://api.example.test/api/auth/apple/callback',
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final adapter = ScriptedHttpClientAdapter();
  container.read(dioProvider).httpClientAdapter = adapter;
  return (repository: container.read(authRepositoryProvider), adapter: adapter);
}

void main() {
  test('login_postsCredentialsAndMapsSignInResult', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/auth/login', [ScriptedReply.json(200, _authJson)]);

    final result = await repository.login(
      email: 'user@example.com',
      password: 'Teeq1234!',
    );

    final request = adapter.requestsTo('/api/auth/login').single;
    expect(request.method, 'POST');
    expect(request.data, {
      'email': 'user@example.com',
      'password': 'Teeq1234!',
    });
    expect(result.tokens.accessToken, 'access');
    expect(result.member.loginType, LoginType.email);
  });

  test('signUp_postsMemberAndMapsSignInResult', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members', [ScriptedReply.json(201, _authJson)]);

    final result = await repository.signUp(
      email: 'user@example.com',
      password: 'Teeq1234!',
      nickname: '티큐',
      serviceTermsAgreed: true,
      privacyPolicyAgreed: true,
    );

    final request = adapter.requestsTo('/api/members').single;
    expect(request.method, 'POST');
    expect(request.data, {
      'email': 'user@example.com',
      'password': 'Teeq1234!',
      'nickname': '티큐',
      'serviceTermsAgreed': true,
      'privacyPolicyAgreed': true,
    });
    expect(result.member.nickname, '티큐');
  });

  test('socialLogin_postsAppleCredential', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/auth/social-login', [
      ScriptedReply.json(200, {
        ..._authJson,
        'nickname': null,
        'loginType': 'APPLE',
      }),
    ]);

    final result = await repository.socialLogin(credential: 'identity-token');

    final request = adapter.requestsTo('/api/auth/social-login').single;
    expect(request.method, 'POST');
    expect(request.data, {
      'socialType': 'APPLE',
      'credential': 'identity-token',
    });
    expect(result.member.loginType, LoginType.apple);
    expect(result.member.isSignupCompleted, isFalse);
  });

  test('logout_postsLogout', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/auth/logout', [ScriptedReply.json(204, null)]);

    await repository.logout();

    final request = adapter.requestsTo('/api/auth/logout').single;
    expect(request.method, 'POST');
  });

  test('fetchMe_getsMemberAndMapsMember', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/me', [ScriptedReply.json(200, _memberJson)]);

    final member = await repository.fetchMe();

    final request = adapter.requestsTo('/api/members/me').single;
    expect(request.method, 'GET');
    expect(member.memberId, 'member-1');
    expect(member.nickname, '티큐');
  });

  test('completeSignup_postsCompletionAndMapsMember', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/me/signup-completion', [
      ScriptedReply.json(200, _memberJson),
    ]);

    final member = await repository.completeSignup(
      nickname: '티큐',
      serviceTermsAgreed: true,
      privacyPolicyAgreed: true,
    );

    final request = adapter
        .requestsTo('/api/members/me/signup-completion')
        .single;
    expect(request.method, 'POST');
    expect(request.data, {
      'nickname': '티큐',
      'serviceTermsAgreed': true,
      'privacyPolicyAgreed': true,
    });
    expect(member.nickname, '티큐');
  });

  test('deleteAccount_sendsDeleteToMe_andAccepts204', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/me', [ScriptedReply.json(204, null)]);

    await repository.deleteAccount();

    final request = adapter.requestsTo('/api/members/me').single;
    expect(request.method, 'DELETE');
  });

  test('deleteAccount_serverFailure_propagatesError', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/me', [
      ScriptedReply.json(502, {
        'errorCode': 'AI_SERVER_UNAVAILABLE',
        'errorMessage': 'unavailable',
      }),
    ]);

    await expectLater(
      repository.deleteAccount(),
      throwsA(
        isA<DioException>().having(
          (error) => error.error,
          'error',
          isA<ApiException>().having(
            (exception) => exception.errorCode,
            'errorCode',
            ErrorCode.aiServerUnavailable,
          ),
        ),
      ),
    );
  });

  test('changeNickname_patchesNicknameAndMapsMember', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/me/nickname', [
      ScriptedReply.json(200, {..._memberJson, 'nickname': '새닉네임'}),
    ]);

    final member = await repository.changeNickname(nickname: '새닉네임');

    final request = adapter.requestsTo('/api/members/me/nickname').single;
    expect(request.method, 'PATCH');
    expect(request.data, {'nickname': '새닉네임'});
    expect(member.nickname, '새닉네임');
  });

  test('changePassword_patchesPasswordsAndMapsSignInResult', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/me/password', [
      ScriptedReply.json(200, _authJson),
    ]);

    final result = await repository.changePassword(
      currentPassword: 'oldpass1',
      newPassword: 'newpass12',
    );

    final request = adapter.requestsTo('/api/members/me/password').single;
    expect(request.method, 'PATCH');
    expect(request.data, {
      'currentPassword': 'oldpass1',
      'newPassword': 'newpass12',
    });
    expect(result.tokens.accessToken, 'access');
    expect(result.tokens.refreshToken, 'refresh');
    expect(result.member.nickname, '티큐');
  });

  group('replaceProfileImage', () {
    Future<RequestOptions> upload(String fileName) async {
      final (:repository, :adapter) = _setUp();
      adapter.on('/api/members/me/profile-image', [
        ScriptedReply.json(200, {
          ..._memberJson,
          'profileImageUrl': 'https://image.example.test/a.jpg',
        }),
      ]);
      final member = await repository.replaceProfileImage(
        ProfileImageFile(fileName: fileName, bytes: Uint8List.fromList([1, 2])),
      );
      expect(member.profileImageUrl, 'https://image.example.test/a.jpg');
      return adapter.requestsTo('/api/members/me/profile-image').single;
    }

    test('putsMultipartImagePartWithJpegContentType', () async {
      final request = await upload('photo.JPG');

      expect(request.method, 'PUT');
      final formData = request.data as FormData;
      expect(formData.files, hasLength(1));
      final part = formData.files.single;
      expect(part.key, 'image');
      expect(part.value.filename, 'photo.JPG');
      expect(part.value.contentType.toString(), 'image/jpeg');
      expect(part.value.length, 2);
    });

    test('usesPngContentTypeForPngExtension', () async {
      final request = await upload('photo.png');

      final part = (request.data as FormData).files.single;
      expect(part.value.contentType.toString(), 'image/png');
    });
  });
}
