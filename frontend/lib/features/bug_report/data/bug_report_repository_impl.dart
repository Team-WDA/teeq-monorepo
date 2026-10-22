import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/network/dio_client.dart';
import 'package:teeq/features/bug_report/data/bug_report_environment_reader_impl.dart';
import 'package:teeq/features/bug_report/domain/bug_report_environment_reader.dart';
import 'package:teeq/features/bug_report/domain/bug_report_repository.dart';
import 'package:teeq/features/bug_report/domain/bug_report_submission.dart';

part 'bug_report_repository_impl.g.dart';

/// [Dio]로 제보 API를 호출하는 구현. 오류는 [ApiErrorInterceptor]가 변환한 채로 전달한다.
final class BugReportRepositoryImpl implements BugReportRepository {
  BugReportRepositoryImpl(this._dio, this._environmentReader);

  final Dio _dio;
  final BugReportEnvironmentReader _environmentReader;

  @override
  Future<String> submit(BugReportSubmission submission) async {
    final environment = await _environmentReader.read();
    final logSnapshot = submission.logSnapshot;
    final requestBody = {
      'source': submission.source.wireValue,
      'content': submission.content,
      'environment': {
        'appVersion': environment.appVersion,
        'platform': environment.platform,
        'osVersion': environment.osVersion,
        'deviceModel': environment.deviceModel,
      },
      if (logSnapshot != null) ...{
        'errorLogs': logSnapshot.errorLogs,
        'networkLogs': logSnapshot.networkLogs,
        'omittedErrorLogCount': logSnapshot.omittedErrorLogCount,
        'omittedNetworkLogCount': logSnapshot.omittedNetworkLogCount,
      },
    };
    final formData = FormData();
    formData.files.add(
      MapEntry(
        'request',
        MultipartFile.fromString(
          jsonEncode(requestBody),
          // 파일명이 없으면 Tomcat이 폼 파라미터(2MB 제한)로 파싱하므로 파일 파트로 보낸다.
          filename: 'request.json',
          contentType: DioMediaType('application', 'json'),
        ),
      ),
    );
    for (final imagePath in submission.imagePaths) {
      formData.files.add(
        MapEntry('images', await MultipartFile.fromFile(imagePath)),
      );
    }
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/bug-reports',
      data: formData,
    );
    return response.data!['bugReportId'] as String;
  }
}

@Riverpod(keepAlive: true)
BugReportRepository bugReportRepository(Ref ref) => BugReportRepositoryImpl(
  ref.watch(dioProvider),
  ref.watch(bugReportEnvironmentReaderProvider),
);
