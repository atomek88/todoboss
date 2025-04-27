import 'package:todoApp/feature/counter/views/android/home_view.dart';
import 'package:todoApp/feature/counter/views/ios/home_view.dart';
import 'package:todoApp/shared/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class CounterWrapperPage extends StatelessWidget {
  const CounterWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(
        const AndroidCounterHome(title: 'Riverpod Demo'),
        const IOSCounterHome(title: 'Riverpod Demo(ios)'));
  }
}
