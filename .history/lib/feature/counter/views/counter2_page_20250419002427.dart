import 'package:todoApp/feature/counter2/views/android/home_view.dart';
import 'package:todoApp/feature/counter2/views/ios/home_view.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class Counter2WrapperPage extends StatelessWidget {
  const Counter2WrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(
        const AndroidCounterHome(title: 'Riverpod Demo'),
        const IOSCounterHome(title: 'Riverpod Demo(ios)'));
  }
}
