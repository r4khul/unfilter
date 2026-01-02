import 'package:flutter/material.dart';

class AppsListSkeleton extends StatefulWidget {
  const AppsListSkeleton({super.key});

  @override
  State<AppsListSkeleton> createState() => _AppsListSkeletonState();
}

class _AppsListSkeletonState extends State<AppsListSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header texts
                  _SkeletonBox(width: 120, height: 14),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 200, height: 32),
                  const SizedBox(height: 24),

                  // Search bar
                  _SkeletonBox(width: double.infinity, height: 50, radius: 16),
                  const SizedBox(height: 16),

                  // Category slider
                  Row(
                    children: [
                      _SkeletonBox(width: 80, height: 32, radius: 16),
                      const SizedBox(width: 8),
                      _SkeletonBox(width: 100, height: 32, radius: 16),
                      const SizedBox(width: 8),
                      _SkeletonBox(width: 90, height: 32, radius: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const _AppCardSkeleton(),
              childCount: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _AppCardSkeleton extends StatelessWidget {
  const _AppCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          const _SkeletonBox(
            width: 40,
            height: 40,
            radius: 20,
          ), // Circle Avatar
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBox(width: 140, height: 16),
                const SizedBox(height: 8),
                const _SkeletonBox(width: 180, height: 12),
                const SizedBox(height: 12),
                const _SkeletonBox(width: 80, height: 24, radius: 20), // Pill
              ],
            ),
          ),
        ],
      ),
    );
  }
}
