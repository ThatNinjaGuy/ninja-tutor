import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// AI tip card widget for contextual AI suggestions
class AiTipCard extends StatelessWidget {
  const AiTipCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.actionText,
    this.onAction,
    this.onDismiss,
    this.showDismiss = true,
  });

  final String title;
  final String content;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool showDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(
          color: AppTheme.aiTipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          gradient: LinearGradient(
            colors: [
              AppTheme.aiTipColor.withOpacity(0.05),
              AppTheme.aiTipColor.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.aiTipColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme.aiTipColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.aiTipColor,
                      ),
                    ),
                  ),
                  
                  if (showDismiss)
                    IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              
              // Action button
              if (actionText != null && onAction != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.aiTipColor,
                      backgroundColor: AppTheme.aiTipColor.withOpacity(0.1),
                    ),
                    child: Text(actionText!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated AI tip card with fade-in animation
class AnimatedAiTipCard extends StatefulWidget {
  const AnimatedAiTipCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.actionText,
    this.onAction,
    this.onDismiss,
    this.showDismiss = true,
    this.delay = Duration.zero,
  });

  final String title;
  final String content;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool showDismiss;
  final Duration delay;

  @override
  State<AnimatedAiTipCard> createState() => _AnimatedAiTipCardState();
}

class _AnimatedAiTipCardState extends State<AnimatedAiTipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start animation after delay
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: AiTipCard(
              title: widget.title,
              content: widget.content,
              icon: widget.icon,
              actionText: widget.actionText,
              onAction: widget.onAction,
              onDismiss: widget.onDismiss,
              showDismiss: widget.showDismiss,
            ),
          ),
        );
      },
    );
  }
}

/// Compact AI tip card for smaller spaces
class CompactAiTipCard extends StatelessWidget {
  const CompactAiTipCard({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
    this.onTap,
    this.onDismiss,
  });

  final String title;
  final String content;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppTheme.aiTipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                AppTheme.aiTipColor.withOpacity(0.05),
                AppTheme.aiTipColor.withOpacity(0.02),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.aiTipColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.aiTipColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.aiTipColor,
                        ),
                      ),
                      Text(
                        content,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.aiTipColor,
                    size: 16,
                  ),
                
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AI tip carousel for multiple tips
class AiTipCarousel extends StatefulWidget {
  const AiTipCarousel({
    super.key,
    required this.tips,
    this.autoPlay = true,
    this.autoPlayDuration = const Duration(seconds: 5),
  });

  final List<AiTip> tips;
  final bool autoPlay;
  final Duration autoPlayDuration;

  @override
  State<AiTipCarousel> createState() => _AiTipCarouselState();
}

class _AiTipCarouselState extends State<AiTipCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.autoPlay && widget.tips.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayDuration, () {
      if (mounted && widget.tips.length > 1) {
        final nextPage = (_currentPage + 1) % widget.tips.length;
        _pageController.animateToPage(
          nextPage,
          duration: AppConstants.shortAnimation,
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tips.isEmpty) return const SizedBox.shrink();
    if (widget.tips.length == 1) {
      final tip = widget.tips.first;
      return AiTipCard(
        title: tip.title,
        content: tip.content,
        icon: tip.icon,
        actionText: tip.actionText,
        onAction: tip.onAction,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.tips.length,
            itemBuilder: (context, index) {
              final tip = widget.tips[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CompactAiTipCard(
                  title: tip.title,
                  content: tip.content,
                  icon: tip.icon,
                  onTap: tip.onAction,
                ),
              );
            },
          ),
        ),
        
        if (widget.tips.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.tips.length,
              (index) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage
                      ? AppTheme.aiTipColor
                      : AppTheme.aiTipColor.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Data class for AI tips
class AiTip {
  const AiTip({
    required this.title,
    required this.content,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String content;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
}
