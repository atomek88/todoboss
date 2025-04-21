import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:todoApp/feature/shared/utils/platform.dart';

@RoutePage()
class ProfileWrapperPage extends StatelessWidget {
  const ProfileWrapperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return getPlatformSpecificPage(const ProfilePage(), const IOSTodosPage());
  }
}
