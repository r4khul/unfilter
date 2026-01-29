library;

import 'package:flutter/material.dart';

import '../../../domain/entities/device_app.dart';
import 'common_widgets.dart';
import 'constants.dart';
import 'premium_modal_header.dart';

class PermissionsSection extends StatelessWidget {
  final DeviceApp app;

  static const int maxVisible = 5;

  const PermissionsSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedPermissions = app.permissions.take(maxVisible).toList();
    final remainingCount = app.permissions.length - maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Permissions"),
        const SizedBox(height: AppDetailsSpacing.standard),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDetailsSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(
                AppDetailsOpacity.mediumLight,
              ),
            ),
            borderRadius: BorderRadius.circular(AppDetailsBorderRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...displayedPermissions.map((p) => _PermissionRow(permission: p)),
              if (remainingCount > 0) ...[
                const SizedBox(height: AppDetailsSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showAllPermissions(context, theme),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDetailsSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDetailsBorderRadius.md,
                        ),
                      ),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(
                          AppDetailsOpacity.half,
                        ),
                      ),
                    ),
                    child: Text(
                      "View $remainingCount More",
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAllPermissions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              PremiumModalHeader(
                title: "Permissions",
                icon: Icons.security_rounded,
                onClose: () => Navigator.pop(context),
              ),
              Expanded(child: _buildPermissionsList(controller, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionsList(ScrollController controller, ThemeData theme) {
    return ListView.builder(
      controller: controller,
      itemCount: app.permissions.length,
      itemBuilder: (context, index) {
        final permission = app.permissions[index];
        return ListTile(
          leading: Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            permission.split('.').last,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            permission,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: AppDetailsFontSizes.sm,
              color: theme.colorScheme.onSurface.withOpacity(
                AppDetailsOpacity.half,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String permission;

  const _PermissionRow({required this.permission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDetailsSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: AppDetailsSizes.iconSmall + 2,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppDetailsSpacing.sm),
          Expanded(
            child: Text(
              permission.split('.').last,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
