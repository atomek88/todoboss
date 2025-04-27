import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:todoApp/shared/animations/animation_constants.dart';
import 'package:todoApp/shared/utils/theme/color_scheme.dart';

/// A beautiful animated button with press, hover, and focus effects
class AnimatedButton extends StatefulWidget {
  /// The child widget to display inside the button
  final Widget child;
  
  /// Callback when the button is pressed
  final VoidCallback? onPressed;
  
  /// Background color of the button
  final Color? backgroundColor;
  
  /// Foreground color of the button (text/icon color)
  final Color? foregroundColor;
  
  /// Border radius of the button
  final BorderRadius? borderRadius;
  
  /// Elevation of the button
  final double elevation;
  
  /// Whether to show a splash effect when pressed
  final bool showSplash;
  
  /// Whether the button is enabled
  final bool enabled;
  
  /// Width of the button (null for auto)
  final double? width;
  
  /// Height of the button (null for auto)
  final double? height;
  
  /// Padding inside the button
  final EdgeInsetsGeometry padding;

  const AnimatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.elevation = 2.0,
    this.showSplash = true,
    this.enabled = true,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: AnimationConstants.veryFast,
      vsync: this,
    );
    
    // Create scale animation
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.defaultCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    
    setState(() {
      _isPressed = true;
    });
    
    _controller.forward();
    
    if (widget.showSplash) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    
    setState(() {
      _isPressed = false;
    });
    
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    
    setState(() {
      _isPressed = false;
    });
    
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? lightColorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? lightColorScheme.onPrimary;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12.0);
    
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? backgroundColor
                        : backgroundColor.withOpacity(0.6),
                    borderRadius: borderRadius,
                    boxShadow: [
                      if (widget.enabled && widget.elevation > 0 && !_isPressed)
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.4),
                          blurRadius: widget.elevation * 2,
                          spreadRadius: widget.elevation / 2,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    border: _isFocused
                        ? Border.all(
                            color: foregroundColor.withOpacity(0.5),
                            width: 2.0,
                          )
                        : null,
                  ),
                  child: Opacity(
                    opacity: widget.enabled ? 1.0 : 0.7,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: foregroundColor,
                        ),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
