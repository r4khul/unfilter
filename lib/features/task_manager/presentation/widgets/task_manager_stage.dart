library;

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TaskManagerStage extends StatelessWidget {
  final bool isLoading;
  final bool isRefreshing;
  final Widget child;

  const TaskManagerStage({
    super.key,
    required this.isLoading,
    this.isRefreshing = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuad,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (Widget child, Animation<double> animation) {
            final isEntering = child.key == const ValueKey('content');

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: isEntering
                      ? const Offset(0, 0.05)
                      : const Offset(0, -0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: isLoading
              ? _buildLoadingState(context)
              : KeyedSubtree(key: const ValueKey('content'), child: child),
        ),
        if (isRefreshing && !isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _RefreshingIndicator()),
          ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    // Assign a key to the loading state to ensure AnimatedSwitcher recognizes it as a different widget
    return KeyedSubtree(
      key: const ValueKey('loading'),
      child: _buildSkeleton(context),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 60)),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(child: _TaskManagerSkeleton(theme: theme)),
        ),
      ],
    );
  }
}

class _RefreshingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Refreshing...",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskManagerSkeleton extends StatelessWidget {
  final ThemeData theme;

  const _TaskManagerSkeleton({required this.theme});

  @override
  Widget build(BuildContext context) {
    final skeletonColor = theme.brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15);

    final highlightColor = theme.brightness == Brightness.light
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.05);

    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: skeletonColor,
        highlightColor: highlightColor,
        duration: const Duration(milliseconds: 1500),
      ),
      containersColor: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                height: 18,
                width: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...List.generate(4, (index) => _buildListItemSkeleton()),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 140, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 100, color: Colors.white),
                ],
              ),
            ),
            Container(width: 50, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
