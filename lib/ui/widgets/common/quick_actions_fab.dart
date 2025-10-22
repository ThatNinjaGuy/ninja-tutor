import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics_helper.dart';

/// Quick action item data
class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// Speed dial FAB with quick actions
class QuickActionsFAB extends StatefulWidget {
  const QuickActionsFAB({
    super.key,
    required this.actions,
    this.heroTag = 'quick_actions',
  });

  final List<QuickAction> actions;
  final String heroTag;

  @override
  State<QuickActionsFAB> createState() => _QuickActionsFABState();
}

class _QuickActionsFABState extends State<QuickActionsFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi / 4, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    HapticsHelper.medium();
  }

  void _handleActionTap(QuickAction action) {
    _toggle(); // Close the menu
    Future.delayed(const Duration(milliseconds: 300), () {
      action.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

        // Action buttons
        ..._buildActionButtons(theme),

        // Main FAB
        Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value,
                child: FloatingActionButton(
                  heroTag: widget.heroTag,
                  onPressed: _toggle,
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(ThemeData theme) {
    if (!_isExpanded) return [];

    final buttons = <Widget>[];
    final spacing = 72.0;

    for (var i = 0; i < widget.actions.length; i++) {
      final action = widget.actions[i];
      final offset = (i + 1) * spacing;

      buttons.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          bottom: 16 + offset,
          right: 16,
          child: _QuickActionButton(
            action: action,
            onTap: () => _handleActionTap(action),
            delay: Duration(milliseconds: i * 50),
          ),
        ),
      );
    }

    return buttons.reversed.toList();
  }
}

/// Individual quick action button
class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({
    required this.action,
    required this.onTap,
    this.delay = Duration.zero,
  });

  final QuickAction action;
  final VoidCallback onTap;
  final Duration delay;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.action.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Button
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.createGlow(
                      widget.action.color ?? theme.colorScheme.primary,
                      intensity: 0.3,
                    ),
                  ),
                  child: FloatingActionButton(
                    heroTag: 'quick_action_${widget.action.label}',
                    mini: true,
                    backgroundColor: widget.action.color ?? theme.colorScheme.primary,
                    onPressed: () {
                      HapticsHelper.light();
                      widget.onTap();
                    },
                    child: Icon(
                      widget.action.icon,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

