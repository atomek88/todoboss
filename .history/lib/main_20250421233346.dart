import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/feature/shared/navigation/app_router.dart';
import 'package:todoApp/feature/shared/utils/theme/theme.dart';
import 'package:todoApp/feature/shared/utils/theme/cupertino_theme.dart';
import 'package:todoApp/l10n/app_localizations.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  // final dir = await getApplicationDocumentsDirectory();
  // Hive.defaultDirectory = dir.path;
  // Initialize Hive storage
  await StorageService.initialize();

  // Run the app with ProviderScope
  runApp(ProviderScope(
    child: MyApp(
      launchTitle: 'Todo App',
    ),
  ));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({
    required this.launchTitle,
    super.key,
  });
  final String launchTitle;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoApp.router(
        title: widget.launchTitle,
        // theme settings
        theme: lightCupertinoTheme(),
        // For dark mode support
        // The CupertinoApp doesn't have a direct darkTheme property like MaterialApp
        // Instead, it uses the theme property and respects the system brightness
        // use auto router to decide widget
        routerConfig: _appRouter.config(),
        localizationsDelegates: Loc.localizationsDelegates,
        supportedLocales: const [
          Locale('en', ''),
        ],
      );
    } else {
      return MaterialApp.router(
        title: widget.launchTitle,
        // theme settings
        // theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
        // use auto router to decide widget
        theme: lightTheme(context),
        darkTheme: darkTheme(context),
        routerConfig: _appRouter.config(),
        localizationsDelegates: Loc.localizationsDelegates,
        supportedLocales: const [
          Locale('en', ''),
        ],
      );
    }
  }
}
