import 'package:ai_friend/app.dart';
import 'package:ai_friend/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  AppConfig.current.validate();
  runApp(const ProviderScope(child: App()));
}
