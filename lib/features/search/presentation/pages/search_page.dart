import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../../../apps/presentation/widgets/category_slider.dart';
import '../../../apps/presentation/widgets/app_card.dart';
import '../widgets/tech_stack_filter.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final apps = ref.watch(filteredAppsProvider);
    final searchQuery = ref.watch(searchFilterProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Search apps...",
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.hintColor.withOpacity(0.5),
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () {
                                          ref
                                                  .read(
                                                    searchFilterProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              '';
                                        },
                                      )
                                    : null,
                              ),
                              style: theme.textTheme.bodyLarge,
                              onChanged: (val) =>
                                  ref
                                          .read(searchFilterProvider.notifier)
                                          .state =
                                      val,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const TechStackFilter(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Slider
                  const CategorySlider(isCompact: false),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: apps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No apps found",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 16, bottom: 32),
                      itemCount: apps.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return AppCard(app: apps[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
