import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'package:todoApp/feature/shared/utils/styles/app_color.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle,
    this.elevation,
    this.brightness,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool? centerTitle;
  final double? elevation;
  final Brightness? brightness;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Use platform-specific app bar based on the platform
    return Platform.isIOS ? _buildCupertinoAppBar(context) : _buildMaterialAppBar(context);
  }

  Widget _buildMaterialAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    
    return AppBar(
      backgroundColor: backgroundColor ?? context.color.backgroundPrimary,
      foregroundColor: foregroundColor ?? context.color.textPrimary,
      elevation: elevation ?? 1.0,
      centerTitle: centerTitle ?? false,
      leading: leading,
      actions: actions,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: foregroundColor ?? context.color.textPrimary,
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      shadowColor: Colors.black26,
    );
  }

  Widget _buildCupertinoAppBar(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    
    return CupertinoNavigationBar(
      backgroundColor: backgroundColor ?? context.color.backgroundPrimary,
      border: Border(
        bottom: BorderSide(
          color: Colors.black12,
          width: 0.5,
        ),
      ),
      leading: leading,
      trailing: actions != null && actions!.isNotEmpty 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ) 
          : null,
      middle: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? context.color.textPrimary,
          fontSize: isSmallScreen ? 17 : 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
