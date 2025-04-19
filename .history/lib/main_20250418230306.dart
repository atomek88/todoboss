import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todoApp/feature/shared/navigation/app_router.dart';
import 'package:todoApp/feature/shared/utils/styles/app_theme.dart';

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
  final _appRouter = AndroidAppRouter();
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CupertinoApp.router(
        title: widget.launchTitle,
        // theme settings
        theme: const CupertinoThemeData(brightness: Brightness.light),
        // use auto router to decide widget
        routerConfig: _appRouter.config(),
      );
    } else {
      return MaterialApp.router(
        title: widget.launchTitle,
        // theme settings
        theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
        // use auto router to decide widget
        routerConfig: _appRouter.config(),
      );
    }
  }
}
