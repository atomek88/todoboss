import 'package:flutter/material.dart';
import 'package:todoApp/shared/utils/theme/theme_extension.dart';

class SharedSliverAppBar extends StatelessWidget {
  const SharedSliverAppBar({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: context.backgroundPrimary, // background color
      foregroundColor: context.textPrimary, // text color
      title: Text(' User $title Repositories'),
      floating: true,
    );
  }
}
