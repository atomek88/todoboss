import 'package:flutter/cupertino.dart';

CupertinoThemeData lightCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFFCD7F32), // Warm bronze primary
    primaryContrastingColor: Color(0xFFF8F0E3), // Light cream contrast
    barBackgroundColor: Color(0xFFF5EFE6), // Warm surface color
    scaffoldBackgroundColor: Color(0xFFF8F0E3), // Warm background
    textTheme: CupertinoTextThemeData(
      primaryColor: Color(0xFFCD7F32), // Warm bronze primary
      textStyle: TextStyle(
        inherit: false,
        color: Color(0xFF3E2723), // Dark brown for readability
        fontFamily: 'IBMPlexMono',
        fontSize: 17.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      actionTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFFCD7F32), // Warm bronze primary
        fontFamily: 'IBMPlexMono',
        fontSize: 17.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      navTitleTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFF3E2723), // Dark brown for readability
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
        fontSize: 17.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFF3E2723), // Dark brown for readability
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
        fontSize: 34.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      tabLabelTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFF3E2723), // Dark brown for readability
        fontFamily: 'IBMPlexMono',
        fontSize: 10.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
    ),
  );
}

CupertinoThemeData darkCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFFE8C9A3), // Warm light bronze
    primaryContrastingColor: Color(0xFF3E2723), // Dark brown contrast
    barBackgroundColor: Color(0xFF3E2723), // Dark warm surface
    scaffoldBackgroundColor: Color(0xFF33251F), // Dark warm background
    textTheme: CupertinoTextThemeData(
      primaryColor: Color(0xFFE8C9A3), // Warm light bronze
      textStyle: TextStyle(
        inherit: false,
        color: Color(0xFFF5EFE6), // Light cream for readability
        fontFamily: 'IBMPlexMono',
        fontSize: 17.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      actionTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFFE8C9A3), // Warm light bronze
        fontFamily: 'IBMPlexMono',
        fontSize: 17.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      navTitleTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFFF5EFE6), // Light cream for readability
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
        fontSize: 17.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      navLargeTitleTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFFF5EFE6), // Light cream for readability
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
        fontSize: 34.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
      tabLabelTextStyle: TextStyle(
        inherit: false,
        color: Color(0xFFF5EFE6), // Light cream for readability
        fontFamily: 'IBMPlexMono',
        fontSize: 10.0,
        letterSpacing: -0.4,
        decoration: TextDecoration.none,
        height: 1.2,
        backgroundColor: null,
        decorationColor: null,
        decorationThickness: null,
        wordSpacing: null,
      ),
    ),
  );
}
