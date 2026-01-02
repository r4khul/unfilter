import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../../../apps/presentation/widgets/apps_list_skeleton.dart';
import '../../../search/presentation/providers/tech_stack_provider.dart';
import '../widgets/home_sliver_delegate.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);
    final theme = Theme.of(context);

    // Calculate heights
    // Search(50) + V-Spacing(12) + Category(40) + V-Spacing(12) = 114
    // + Toolbar(56) = 170 + Top Padding
    final topPadding = MediaQuery.of(context).padding.top;
    final minHeight = 170.0 + topPadding;
    final maxHeight = 260.0 + topPadding;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // No standard AppBar, we use SliverPersistentHeader
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: appsAsync.when(
          data: (apps) {
            final category = ref.watch(categoryFilterProvider);
            final techStack = ref.watch(techStackFilterProvider);

            final filteredApps = apps.where((app) {
              final matchesCategory =
                  category == null || app.category == category;
              bool matchesStack = true;
              if (techStack != null && techStack != 'All') {
                if (techStack == 'Android') {
                  matchesStack = [
                    'Java',
                    'Kotlin',
                    'Android',
                  ].contains(app.stack);
                } else {
                  matchesStack =
                      app.stack.toLowerCase() == techStack.toLowerCase();
                }
              }
              return matchesCategory && matchesStack;
            }).toList();

            return CustomScrollView(
              key: const ValueKey('data'),
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeSliverDelegate(
                    appCount: apps.length,
                    expandedHeight: maxHeight,
                    collapsedHeight: minHeight,
                  ),
                ),
                filteredApps.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.app_blocking_outlined,
                                size: 64,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No apps found matching criteria",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          10,
                          20,
                          20 + MediaQuery.of(context).padding.bottom,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(app: filteredApps[index]),
                            ),
                            childCount: filteredApps.length,
                          ),
                        ),
                      ),
              ],
            );
          },
          loading: () => const AppsListSkeleton(key: ValueKey('loading')),
          error: (err, stack) => Center(
            key: const ValueKey('error'),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Something went wrong while scanning.\n$err",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
