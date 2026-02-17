import 'package:flutter/material.dart';

import '../../widgets/external_link_tile.dart';
import '../../widgets/github_cta_card.dart';
import '../../widgets/premium_app_bar.dart';
import '../../../../../core/widgets/top_shadow_gradient.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46.0 + (8.0 * 2) + MediaQuery.of(context).padding.top,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 16),
                      _buildIntroText(theme),
                      const SizedBox(height: 24),
                      const ExternalLinkTile(
                        label: 'Detailed Policy',
                        value: 'Check Here',
                        url:
                            'https://gist.github.com/r4khul/cd8f4828a89dcbd1bae661eed659e1c3',
                      ),
                      const SizedBox(height: 48),
                      const _PolicySection(
                        title: 'Local Processing',
                        content:
                            'Every scan, every match, every bit of analysis runs '
                            "right on your phone. We couldn't peek at your apps "
                            'even if we wanted to—we built it that way.',
                        icon: Icons.phonelink_lock_rounded,
                      ),
                      const _PolicySection(
                        title: 'Minimal Permissions',
                        content:
                            'We ask for exactly two things: permission to see what '
                            'apps you have installed, and storage access for '
                            "digging into native libraries. That's it.",
                        icon: Icons.verified_user_rounded,
                      ),
                      const _PolicySection(
                        title: 'No Tracking',
                        content:
                            'No analytics. No ad SDKs. No crash reporters phoning '
                            'home. What you do inside the app stays between you '
                            'and your phone.',
                        icon: Icons.do_not_disturb_on_rounded,
                      ),
                      const _PolicySection(
                        title: 'Limited Networking',
                        content:
                            'The only time we hit the internet? To check for '
                            "updates and grab the GitHub star count. That's it—"
                            'nothing about you leaves this app.',
                        icon: Icons.wifi_rounded,
                      ),
                      const SizedBox(height: 20),
                      const GithubCtaCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const TopShadowGradient(),
          PremiumAppBar(
            title: 'Privacy Policy',
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      'Your Data,\nYour Device',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1.0,
      ),
    );
  }

  Widget _buildIntroText(ThemeData theme) {
    return Text(
      "Privacy isn't a feature we tacked on—it's baked into how this app "
      'works. UnFilter runs offline because the only way to do this right.',
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        height: 1.6,
        fontSize: 16,
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _PolicySection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconContainer(theme),
          const SizedBox(width: 20),
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildIconContainer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 24),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
