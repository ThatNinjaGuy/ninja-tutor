import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/animation_helper.dart';

/// Skeleton loader widget with shimmer effect
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 4,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _animation = AnimationHelper.createShimmerAnimation(
      controller: _controller,
      begin: -1.2,
      end: 2.2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (baseColor, highlightColor) = context.shimmerColors;

    final borderRadius = BorderRadius.circular(widget.borderRadius);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerPosition = _animation.value;
        final stops = <double>[
          (shimmerPosition - 0.3).clamp(0.0, 1.0),
          shimmerPosition.clamp(0.0, 1.0),
          (shimmerPosition + 0.35).clamp(0.0, 1.0),
        ];

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: stops,
            ),
          ),
        );
      },
    );
  }
}

/// Book card skeleton loader
class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({
    super.key,
    this.isGrid = false,
  });

  final bool isGrid;

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover skeleton
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const SkeletonLoader(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Title skeleton
              const SkeletonLoader(width: double.infinity, height: 14, borderRadius: 6),
              const SizedBox(height: 4),
              
              // Author skeleton
              const SkeletonLoader(width: 100, height: 12, borderRadius: 6),
              const Spacer(),
              
              // Subject chip skeleton
              const SkeletonLoader(width: double.infinity, height: 20, borderRadius: 10),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Book cover skeleton
            const SkeletonLoader(width: 60, height: 84, borderRadius: 10),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: double.infinity, height: 16, borderRadius: 6),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 120, height: 14, borderRadius: 6),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SkeletonLoader(width: 80, height: 20, borderRadius: 12),
                      const SizedBox(width: 8),
                      const SkeletonLoader(width: 40, height: 12, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid skeleton loader
class GridSkeletonLoader extends StatelessWidget {
  const GridSkeletonLoader({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const BookCardSkeleton(isGrid: true),
    );
  }
}

/// List skeleton loader
class ListSkeletonLoader extends StatelessWidget {
  const ListSkeletonLoader({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: const BookCardSkeleton(),
      ),
    );
  }
}

