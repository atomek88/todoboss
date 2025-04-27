import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/app_flavour/app_config.dart';

import 'package:todoApp/main.dart';

void sharedMain(AppConfig appConfig,
    {List<Override> overrides = const []}) async {
  await init(appConfig);

  // final List<Override> allOverrides = [
  //   appProvider.overrideWithValue(
  //     ApiConfig(appConfig.apiBaseUrl, apiKey: appConfig.appApiKey),
  //   ),
  // ];
  // allOverrides.addAll(overrides);
  runApp(
    ProviderScope(
      // overrides: allOverrides,
      child: MyApp(launchTitle: appConfig.launchTitle),
    ),
  );
}

// use this to connect to APIs when app opens
Future<void> init(AppConfig appConfig) {
  debugPrint('sharedMain launch title  ${appConfig.launchTitle}');
  debugPrint('sharedMain environment  ${appConfig.environment}');
  debugPrint('sharedMain base url ${appConfig.apiBaseUrl}');
  // TODO initialize others here
  // eg. crashlitics
  // orientation
  // etc.
  return Future.value();
}
