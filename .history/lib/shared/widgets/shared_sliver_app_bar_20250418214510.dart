import 'package:flutter/material.dart';
import 'package:todoApp/feature/shared/utils/styles/app_color.dart';

class SharedSliverAppBar extends StatelessWidget {
  const SharedSliverAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: context.color.backgroundPrimary, // background color
      foregroundColor: context.color.textPrimary, // text color
      title: Text(' User $title Repositories'),
      floating: true,
    );
  }
}
