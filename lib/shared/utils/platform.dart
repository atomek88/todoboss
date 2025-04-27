// Platform detection helper
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget getPlatformSpecificPage(Widget? materialPage, Widget? cupertinoPage) {
  if (materialPage == null && cupertinoPage == null) {
    throw ArgumentError('At least one platform-specific page must be provided');
  }
  if (materialPage == null) {
    return cupertinoPage!;
  }
  if (cupertinoPage == null) {
    return materialPage;
  }
  if (Platform.isIOS) {
    return cupertinoPage;
  } else {
    return materialPage;
  }
}
