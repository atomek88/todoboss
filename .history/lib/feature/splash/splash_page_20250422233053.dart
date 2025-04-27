import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:todoApp/shared/animations/launch_screen_animation.dart';
import 'package:todoApp/shared/navigation/app_router.gr.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';

@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // We'll navigate in the onAnimationComplete callback of LaunchScreenAnimation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColorScheme.background,
      body: LaunchScreenAnimation(
        backgroundColor: lightColorScheme.background,
        logo: Image.asset(
          'assets/icons/rock-hill.png', // Using an existing icon from the app
          width: 80,
          height: 80,
        ),
        onAnimationComplete: () {
          // Navigate to the home screen when animation completes
          context.router.replace(const HomeWrapperRoute());
        },
      ),
    );
  }
}
