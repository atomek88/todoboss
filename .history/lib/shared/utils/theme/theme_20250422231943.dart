import 'package:flutter/material.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';
import 'package:todoApp/shared/utils/theme/text_theme.dart';

// user a cupertino theme for lightColorScheme and textTheme
// CupertinoThemeData.light()

ThemeData lightTheme(BuildContext context) => ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      textTheme: textTheme(ThemeData().textTheme),
    );

ThemeData darkTheme(BuildContext context) => ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      textTheme: textTheme(ThemeData.dark().textTheme),
    );
