import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/feature/shared/app_flavour/app_config.dart';
import 'package:todoApp/feature/shared/app_flavour/shared_main.dart';

void main() async {
  // different for each flavours
  final appConfig = AppConfig(
    // just test with dev
    environment: AppEnvironment.dev,
    apiBaseUrl: 'DevBaseUrl.baseUrlDev',
    appApiKey: 'DevBaseUrl.appApiKey',
    launchTitle: 'Mock',
    initializeCrashlytics: false,
  );
  // different for each flavours
  final List<Override> overrides = [
    // override any specific depedency needed
    // override any specific depedency needed for mock
    // override for testing with hard coded data
    // userRepositoryProvider.overrideWith(
    //   (ref) => MockUserRepository(),
    // ),
  ];
  sharedMain(overrides: overrides, appConfig);
}
