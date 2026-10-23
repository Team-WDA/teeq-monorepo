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
  'loginType': 'GOOGLE',
  'profileImageUrl': null,
};

const _authJson = {
  'accessToken': 'access',
  'refreshToken': 'refresh',
  'memberId': 'member-1',
  'nickname': '티큐',
  'hasAiCharacter': false,
  'loginType': 'GOOGLE',
  'profileImageUrl': null,
};

({AuthRepository repository, ScriptedHttpClientAdapter adapter}) _setUp() {
  final container = ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
      appConfigProvider.overrideWithValue(
        const AppConfig(apiBaseUrl: 'https://api.example.test'),
      ),
    ],
  );
  addTearDown(container.dispose);
  final adapter = ScriptedHttpClientAdapter();
  container.read(dioProvider).httpClientAdapter = adapter;
  return (repository: container.read(authRepositoryProvider), adapter: adapter);
}

void main() {
  test('login_postsCredentialAndMapsSignInResult', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/auth/login', [
      ScriptedReply.json(200, {..._authJson, 'loginType': 'APPLE'}),
    ]);

    final result = await repository.login(credential: 'firebase-token');

    final request = adapter.requestsTo('/api/auth/login').single;
    expect(request.method, 'POST');
    expect(request.data, {'credential': 'firebase-token'});
    expect(result.tokens.accessToken, 'access');
    expect(result.member.loginType, LoginType.apple);
    expect(result.member.nickname, '티큐');
  });

  test('signUp_postsCredentialNicknameAndConsents', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/auth/signup', [ScriptedReply.json(201, _authJson)]);

    final result = await repository.signUp(
      credential: 'firebase-token',
      nickname: '티큐',
      serviceTermsAgreed: true,
      privacyPolicyAgreed: true,
    );

    final request = adapter.requestsTo('/api/auth/signup').single;
    expect(request.method, 'POST');
    expect(request.data, {
      'credential': 'firebase-token',
      'nickname': '티큐',
      'serviceTermsAgreed': true,
      'privacyPolicyAgreed': true,
    });
    expect(result.member.loginType, LoginType.google);
  });

  test('checkNicknameAvailability_getsWithQueryAndReturnsFlag', () async {
    final (:repository, :adapter) = _setUp();
    adapter.on('/api/members/nickname-availability', [
      ScriptedReply.json(200, {'available': false}),
    ]);

    final isAvailable = await repository.checkNicknameAvailability(
      nickname: '티큐',
    );

    final request = adapter
        .requestsTo('/api/members/nickname-availability')
        .single;
    expect(request.method, 'GET');
    expect(request.uri.queryParameters, {'nickname': '티큐'});
    expect(isAvailable, isFalse);
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
