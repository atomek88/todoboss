import 'package:flutter/material.dart';
import 'package:todoApp/feature/app/app_tabs.dart';
import 'package:todoApp/l10n/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Starter App',
      theme: lightTheme(context),
      darkTheme: darkTheme(context),
      home: const AppTabs(),
      localizationsDelegates: Loc.localizationsDelegates,
      supportedLocales: const [
        Locale('en', ''),
      ],
    );
  }
}
