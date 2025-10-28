import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics_helper.dart';

/// Gradient button with animated gradient on press
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 12,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final EdgeInsets padding;
  final double borderRadius;
  final bool isLoading;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = false);
              HapticsHelper.light();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        decoration: BoxDecoration(
          gradient: widget.gradient ?? AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: (widget.gradient?.colors.first ?? AppTheme.primaryGradient.colors.first)
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: widget.padding,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : DefaultTextStyle(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      child: widget.child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass button with frosted effect
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.borderRadius = 12,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              HapticsHelper.light();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              padding: widget.padding,
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulse icon button with animation on interaction
class PulseIconButton extends StatefulWidget {
  const PulseIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  @override
  State<PulseIconButton> createState() => _PulseIconButtonState();
}

class _PulseIconButtonState extends State<PulseIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      HapticsHelper.light();
      _controller.forward().then((_) => _controller.reverse());
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.color,
            ),
          );
        },
      ),
      onPressed: _handleTap,
      tooltip: widget.tooltip,
    );
  }
}

