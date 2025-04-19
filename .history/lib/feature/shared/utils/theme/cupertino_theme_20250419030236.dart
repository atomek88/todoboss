import 'package:flutter/cupertino.dart';

CupertinoThemeData lightCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: Color.fromARGB(255, 42, 130, 212), // Using your primary color
    primaryContrastingColor: Color(0xff000000), // Using your onPrimary color
    barBackgroundColor:
        Color.fromARGB(255, 42, 130, 212), // Using your surface color
    scaffoldBackgroundColor:
        Color.fromARGB(255, 42, 130, 212), // Using your background color
    textTheme: CupertinoTextThemeData(
      primaryColor: Color.fromARGB(255, 42, 130, 212),
      textStyle: TextStyle(
        color: Color(0xff000000), // Using your onSurface color
        fontFamily: 'IBMPlexMono',
      ),
      actionTextStyle: TextStyle(
        color: Color.fromARGB(255, 42, 130, 212),
        fontFamily: 'IBMPlexMono',
      ),
      navTitleTextStyle: TextStyle(
        color: Color(0xff000000),
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: Color(0xff000000),
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
        fontSize: 34.0,
      ),
      tabLabelTextStyle: TextStyle(
        color: Color(0xff000000),
        fontFamily: 'IBMPlexMono',
      ),
    ),
  );
}

CupertinoThemeData darkCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: Color.fromARGB(255, 42, 130, 212), // Using your primary color
    primaryContrastingColor: Color(0xff000000), // Using your onPrimary color
    barBackgroundColor: Color(0xff121212), // Using your surface color
    scaffoldBackgroundColor: Color(0xff121212), // Using your background color
    textTheme: CupertinoTextThemeData(
      primaryColor: Color.fromARGB(255, 42, 130, 212),
      textStyle: TextStyle(
        color: Color.fromARGB(255, 42, 130, 212), // Using your onSurface color
        fontFamily: 'IBMPlexMono',
      ),
      actionTextStyle: TextStyle(
        color: Color.fromARGB(255, 42, 130, 212),
        fontFamily: 'IBMPlexMono',
      ),
      navTitleTextStyle: TextStyle(
        color: Color.fromARGB(255, 42, 130, 212),
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: Color.fromARGB(255, 42, 130, 212),
        fontFamily: 'IBMPlexMono',
        fontWeight: FontWeight.bold,
        fontSize: 34.0,
      ),
      tabLabelTextStyle: TextStyle(
        color: Color.fromARGB(255, 42, 130, 212),
        fontFamily: 'IBMPlexMono',
      ),
    ),
  );
}
