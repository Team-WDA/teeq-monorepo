import 'package:teeq/app.dart';
import 'package:teeq/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  AppConfig.current.validate();
  runApp(const ProviderScope(child: App()));
}
