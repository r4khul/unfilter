import 'package:flutter/material.dart';
import '../../../apps/presentation/widgets/category_slider.dart';
import '../../../search/presentation/pages/search_page.dart';
import '../../../search/presentation/widgets/tech_stack_filter.dart';
import 'scan_button.dart';

class HomeSliverDelegate extends SliverPersistentHeaderDelegate {
  final int appCount;
  final double expandedHeight;
  final double collapsedHeight;

  HomeSliverDelegate({
    required this.appCount,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final progress = shrinkOffset / (maxExtent - minExtent);
    final percent = progress.clamp(0.0, 1.0);
    final isCollapsed = percent > 0.8; // Threshold for switching states

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(
              percent > 0.9 ? 0.1 : 0.0,
            ),
          ),
        ),
      ),
      child: Stack(
        children: [
          // 1. Background / Safe Area handling
          Positioned.fill(child: SafeArea(bottom: false, child: Container())),

          // 2. Stats Section (Expanded Only)
          // Fades out and moves up as we scroll
          Positioned(
            top: 60 - (shrinkOffset * 0.5), // Parallax-ish
            left: 20,
            child: Opacity(
              opacity: (1 - percent * 2).clamp(0.0, 1.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Device has",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$appCount Installed Apps",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Search Bar & Categories (Sticky Bottom)
          // These move up to fill the space left by the shrinking Stats Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const SearchPage(),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      const begin = Offset(0.0, 0.1);
                                      const end = Offset.zero;
                                      const curve = Curves.easeOutCubic;
                                      var tween = Tween(
                                        begin: begin,
                                        end: end,
                                      ).chain(CurveTween(curve: curve));
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        ),
                                      );
                                    },
                                transitionDuration: const Duration(
                                  milliseconds: 300,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.4,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Search installed apps...",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const TechStackFilter(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const CategorySlider(
                  isCompact: true,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12), // Bottom spacing
              ],
            ),
          ),

          // 4. Top App Bar (Sticky Top)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Logo / Title Transition
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isCollapsed
                          ? Row(
                              key: const ValueKey('collapsed'),
                              children: [
                                Image.asset(
                                  'assets/icons/findstack-nobg.png',
                                  height: 28,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.install_mobile,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$appCount",
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              "FindStack",
                              key: const ValueKey('expanded'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const Spacer(),
                    const ScanButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(HomeSliverDelegate oldDelegate) {
    return oldDelegate.appCount != appCount ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight;
  }
}
