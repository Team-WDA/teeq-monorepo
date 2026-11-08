import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:teeq/core/analytics/analytics_gateway.dart';

part 'firebase_analytics_gateway.g.dart';

/// Firebase Analytics(GA4)로 이벤트를 보내는 실제 구현.
final class FirebaseAnalyticsGateway implements AnalyticsGateway {
  const FirebaseAnalyticsGateway();

  @override
  Future<void> logScreenView(String screenName) =>
      FirebaseAnalytics.instance.logScreenView(screenName: screenName);

  @override
  Future<void> setUserId(String? userId) =>
      FirebaseAnalytics.instance.setUserId(id: userId);

  @override
  Future<void> setDefaultEventParameters(Map<String, num> parameters) =>
      FirebaseAnalytics.instance.setDefaultEventParameters(parameters);
}

@Riverpod(keepAlive: true)
AnalyticsGateway analyticsGateway(Ref ref) => const FirebaseAnalyticsGateway();

@Riverpod(keepAlive: true)
RouteObserver<ModalRoute<dynamic>> analyticsNavigatorObserver(Ref ref) =>
    FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
