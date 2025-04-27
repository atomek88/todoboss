import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/shared/app_flavour/app_config.dart';

import 'package:todoApp/shared/app_flavour/shared_main.dart';

void main() async {
  // different for each flavours
  final appConfig = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'DevBaseUrl.baseUrlDev',
    appApiKey: 'DevBaseUrl.appApiKey',
    launchTitle: 'Staging',
    initializeCrashlytics: false,
  );
  // different for each flavours
  final List<Override> overrides = [
    // override any specific depedency needed for staging
  ];
  sharedMain(overrides: overrides, appConfig);
}
