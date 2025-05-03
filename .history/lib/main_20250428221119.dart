import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoApp/core/globals.dart';
import 'package:todoApp/core/storage/storage_service.dart';
import 'package:todoApp/shared/navigation/app_router.dart';
import 'package:todoApp/shared/utils/theme/theme.dart';
import 'package:todoApp/shared/utils/theme/cupertino_theme.dart';
import 'package:todoApp/l10n/app_localizations.dart';

void main() async {
  // Set up error handling with Talker
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
  };

  // Handle uncaught async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    talker.handle(error, stack);
    return true;
  };

  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  try {
    await StorageService.initialize();
    talker.debug('Storage service initialized successfully');
  } catch (e) {
    talker.error('Failed to initialize storage service', e);
  }

  // Run the app with ProviderScope
  runApp(ProviderScope(
    overrides: [
      // We pre-initialize the Isar instance to ensure it's ready before any widgets build
      isarProvider.overrideWith((ref) async {
        final storageService = StorageService();
        return await storageService.getIsar();
      }),
    ],
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
