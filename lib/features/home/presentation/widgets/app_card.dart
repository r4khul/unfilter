import 'package:flutter/material.dart';
import '../../domain/device_app.dart';
import 'package:intl/intl.dart';

class AppCard extends StatelessWidget {
  final DeviceApp app;

  const AppCard({super.key, required this.app});

  Color _getStackColor(String stack, bool isDark) {
    if (stack == "Flutter")
      return isDark ? const Color(0xFF42A5F5) : const Color(0xFF02569B);
    if (stack == "React Native")
      return isDark ? const Color(0xFF61DAFB) : const Color(0xFF0D47A1);
    // ... same as before
    return Colors.grey;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return "${duration.inMinutes}m";
    } else {
      return "${duration.inHours}h ${duration.inMinutes % 60}m";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stackColor = _getStackColor(app.stack, isDark);
    final dateFormat = DateFormat('MMM d, y');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: stackColor.withOpacity(0.1),
          child: Text(
            app.appName.isNotEmpty ? app.appName[0].toUpperCase() : "?",
            style: TextStyle(
              color: stackColor,
              fontWeight: FontWeight.bold,
              fontFamily: "UncutSans",
            ),
          ),
        ),
        title: Text(
          app.appName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              app.packageName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stackColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stackColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    app.stack,
                    style: TextStyle(
                      color: stackColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (app.totalTimeInForeground > 0) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time_filled,
                    size: 14,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(app.totalUsageDuration),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: theme.dividerTheme.color),
                  _buildSectionTitle(theme, "APP STATISTICS"),
                  _buildStatRow(
                    theme,
                    "Version",
                    "${app.version} (${app.versionCode})",
                  ),
                  _buildStatRow(
                    theme,
                    "Installed",
                    dateFormat.format(app.installDate),
                  ),
                  _buildStatRow(
                    theme,
                    "Updated",
                    dateFormat.format(app.updateDate),
                  ),
                  _buildStatRow(theme, "Target SDK", "${app.targetSdkVersion}"),
                  _buildStatRow(theme, "Min SDK", "${app.minSdkVersion}"),
                  if (app.lastTimeUsed > 0)
                    _buildStatRow(
                      theme,
                      "Last Used",
                      dateFormat.format(app.lastUsedDate),
                    ),

                  const SizedBox(height: 16),
                  if (app.permissions.isNotEmpty) ...[
                    _buildSectionTitle(
                      theme,
                      "PERMISSIONS (${app.permissions.length})",
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: app.permissions
                          .take(10)
                          .map((p) => _buildChip(theme, p.split('.').last))
                          .toList(),
                    ),
                    if (app.permissions.length > 10)
                      Text(
                        "+ ${app.permissions.length - 10} more",
                        style: theme.textTheme.labelSmall,
                      ),
                  ],

                  const SizedBox(height: 16),
                  if (app.nativeLibraries.isNotEmpty) ...[
                    _buildSectionTitle(theme, "DETECTED LIBRARIES"),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: app.nativeLibraries
                          .map((lib) => _buildChip(theme, lib))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary.withOpacity(0.6),
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(ThemeData theme, String label) {
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
      ),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outline),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
