import 'package:flutter/material.dart';
import 'package:todoApp/feature/shared/utils/theme/color_scheme.dart';
import 'package:todoApp/feature/shared/utils/theme/text_theme.dart';

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
