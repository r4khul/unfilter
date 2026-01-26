import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../common/utils/stack_utils.dart';
import '../../../../core/navigation/navigation.dart';
import '../../domain/entities/device_app.dart';

class AppCard extends StatelessWidget {
  final DeviceApp app;

  const AppCard({super.key, required this.app});

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
    final stackColor = getStackColor(app.stack, isDark);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          AppRouteFactory.toAppDetails(context, app);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: stackColor.withOpacity(0.1),
                    backgroundImage: app.icon != null
                        ? MemoryImage(app.icon!)
                        : null,
                    child: app.icon == null
                        ? Text(
                            app.appName.isNotEmpty
                                ? app.appName[0].toUpperCase()
                                : "?",
                            style: TextStyle(
                              color: stackColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: "UncutSans",
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.packageName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: stackColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: stackColor.withOpacity(0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Skeleton.replace(
                                    width: 14,
                                    height: 14,
                                    child: SvgPicture.asset(
                                      getStackIconPath(app.stack),
                                      width: 14,
                                      height: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      app.stack,
                                      style: TextStyle(
                                        color: stackColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (app.totalTimeInForeground > 0) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time_filled,
                                size: 14,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(app.totalUsageDuration),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            Spacer(),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.1,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.60)
                                        : Colors.grey.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
