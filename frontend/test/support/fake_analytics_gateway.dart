import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/analytics/analytics_gateway.dart';
import 'package:teeq/core/analytics/firebase_analytics_gateway.dart';

/// 호출 내용을 순서대로 메모리에 기록하는 테스트용 분석 게이트웨이.
class FakeAnalyticsGateway implements AnalyticsGateway {
  final List<String> loggedScreenNames = [];
  final List<String?> userIdCalls = [];
  final List<Map<String, num>> defaultEventParametersCalls = [];

  @override
  Future<void> logScreenView(String screenName) async {
    loggedScreenNames.add(screenName);
  }

  @override
  Future<void> setUserId(String? userId) async {
    userIdCalls.add(userId);
  }

  @override
  Future<void> setDefaultEventParameters(Map<String, num> parameters) async {
    defaultEventParametersCalls.add(parameters);
  }
}

/// 앱 provider를 만드는 테스트용 분석 override.
///
/// `FirebaseAnalytics.instance`는 `Firebase.initializeApp` 없이 호출하면 예외를 던지므로
/// 앱 provider를 만드는 테스트는 이 헬퍼를 함께 넘긴다.
List<Override> analyticsTestOverrides([FakeAnalyticsGateway? gateway]) => [
  analyticsGatewayProvider.overrideWithValue(gateway ?? FakeAnalyticsGateway()),
  analyticsNavigatorObserverProvider.overrideWithValue(
    RouteObserver<ModalRoute<dynamic>>(),
  ),
];
