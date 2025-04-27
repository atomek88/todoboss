import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:todoApp/shared/utils/platform.dart';
import 'package:todoApp/feature/profile/views/ios/profile_screen.dart' as ios;
import 'package:todoApp/feature/profile/views/android/profile_screen.dart'
    as android;

@RoutePage()
class ProfileWrapperPage extends StatelessWidget {
  const ProfileWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(
        const android.ProfilePage(), const ios.ProfilePage());
  }
}
