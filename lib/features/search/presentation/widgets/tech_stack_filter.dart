import 'package:unfilter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:unfilter/features/apps/presentation/widgets/app_details/premium_modal_header.dart';
import '../providers/tech_stack_provider.dart';

class TechStackFilter extends ConsumerWidget {
  const TechStackFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedStack = ref.watch(techStackFilterProvider);

    final stacks = [
      {'name': TechStacks.all, 'icon': 'assets/vectors/icon_android.svg'},
      {'name': TechStacks.flutter, 'icon': 'assets/vectors/icon_flutter.svg'},
      {
        'name': TechStacks.reactNative,
        'icon': 'assets/vectors/icon_reactnative.svg',
      },
      {'name': TechStacks.jetpack, 'icon': 'assets/vectors/icon_jetpack.svg'},
      {'name': TechStacks.kotlin, 'icon': 'assets/vectors/icon_kotlin.svg'},
      {'name': TechStacks.java, 'icon': 'assets/vectors/icon_java.svg'},
      {'name': TechStacks.ionic, 'icon': 'assets/vectors/icon_ionic.svg'},
      {'name': TechStacks.xamarin, 'icon': 'assets/vectors/icon_xamarin.svg'},
      {'name': TechStacks.unity, 'icon': 'assets/vectors/icon_unity.svg'},
      {'name': TechStacks.godot, 'icon': 'assets/vectors/icon_godot.svg'},
      {
        'name': TechStacks.capacitor,
        'icon': 'assets/vectors/icon_capacitorjs.svg',
      },
      {
        'name': TechStacks.nativeScript,
        'icon': 'assets/vectors/icon_nativescript.svg',
      },
      {'name': TechStacks.cordova, 'icon': 'assets/vectors/icon_cordova.svg'},
    ];

    void showStackSelector() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        builder: (context) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.zero,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumModalHeader(
                  title: "Filter by Tech",
                  icon: Icons.filter_alt_rounded,
                  onClose: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: stacks.length,
                  itemBuilder: (context, index) {
                    final stack = stacks[index];
                    final isSelected =
                        selectedStack == stack['name'] ||
                        (selectedStack == null &&
                            stack['name'] == TechStacks.all);

                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(techStackFilterProvider.notifier)
                            .setStack(
                              stack['name'] == TechStacks.all
                                  ? null
                                  : stack['name'],
                            );
                        Navigator.pop(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: SvgPicture.asset(
                              stack['icon']!,
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stack['name']!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentIcon = stacks.firstWhere(
      (s) => s['name'] == (selectedStack ?? TechStacks.all),
      orElse: () => stacks[0],
    )['icon']!;

    return GestureDetector(
      onTap: showStackSelector,
      child: Container(
        height: 50,
        width: 50,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkTextSecondary, width: 1),
        ),
        child: SvgPicture.asset(currentIcon, width: 24, height: 24),
      ),
    );
  }
}
