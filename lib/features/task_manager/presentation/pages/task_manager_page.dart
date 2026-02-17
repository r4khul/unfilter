library;

import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_info2/system_info2.dart';

import '../../../home/presentation/widgets/premium_app_bar.dart';
import '../../../../core/widgets/top_shadow_gradient.dart';
import '../../domain/entities/active_app.dart';
import '../../domain/entities/process_with_history.dart';
import '../providers/task_manager_view_model.dart';
import '../widgets/battery_impact_card.dart';
import '../widgets/constants.dart';
import '../widgets/process_list_items.dart';
import '../widgets/system_overview_card.dart';
import '../widgets/task_manager_search_bar.dart';
import '../widgets/task_manager_stage.dart';

class TaskManagerPage extends ConsumerStatefulWidget {
  const TaskManagerPage({super.key});

  @override
  ConsumerState<TaskManagerPage> createState() => _TaskManagerPageState();
}

class _TaskManagerPageState extends ConsumerState<TaskManagerPage> {
  final GlobalKey<_SystemMonitorHeaderState> _headerKey = GlobalKey();

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateTotalCpu(AsyncValue<TaskManagerData> viewModelState) {
    return viewModelState.maybeWhen(
      data: (data) {
        if (data.processesWithHistory.isEmpty) return 0;
        double total = 0;
        for (final proc in data.processesWithHistory) {
          total += proc.currentCpu;
        }
        return total.clamp(0, 100);
      },
      orElse: () => 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModelState = ref.watch(taskManagerViewModelProvider);

    // Only care about process loading for the main stage state
    final isLoading = viewModelState.isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          TaskManagerStage(
            isLoading: isLoading,
            isRefreshing: false,
            child: RefreshIndicator(
              edgeOffset: 120,
              onRefresh: () async {
                ref.invalidate(taskManagerViewModelProvider);
                final headerRefresh =
                    _headerKey.currentState?.refresh() ?? Future.value();
                await headerRefresh;
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height:
                          46.0 + (8.0 * 2) + MediaQuery.of(context).padding.top,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: _SystemMonitorHeader(
                        key: _headerKey,
                        cpuPercentage: _calculateTotalCpu(viewModelState),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  const SliverToBoxAdapter(child: BatteryImpactCard()),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TaskManagerSpacing.lg,
                      ),
                      child: TaskManagerSearchBar(
                        controller: _searchController,
                        searchQuery: _searchQuery,
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ),

                  _buildProcessList(viewModelState, theme),

                  const SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: TaskManagerSpacing.listBottom,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const TopShadowGradient(),
          PremiumAppBar(
            title: "Task Manager",
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessList(
    AsyncValue<TaskManagerData> viewModelState,
    ThemeData theme,
  ) {
    return viewModelState.when(
      data: (data) => _buildProcessListContent(data, theme),
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (error, _) => _buildErrorState(theme, error.toString()),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: theme.colorScheme.error.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                "Failed to load processes",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(taskManagerViewModelProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessListContent(TaskManagerData data, ThemeData theme) {
    var processesWithHistory = data.processesWithHistory;
    var activeApps = data.activeApps;
    final matches = data.matches;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      processesWithHistory = _filterProcesses(processesWithHistory, query);
      activeApps = _filterActiveApps(activeApps, query);
    }

    final List<Widget> listItems = [];

    if (data.hasProcessError && processesWithHistory.isEmpty) {
      listItems.add(
        _ProcessErrorBanner(
          error: data.processError!.message,
          onRetry: () => ref.invalidate(taskManagerViewModelProvider),
        ),
      );
    }

    if (processesWithHistory.isNotEmpty) {
      listItems.add(const ProcessSectionHeader(title: "KERNEL / SYSTEM"));
      for (var proc in processesWithHistory) {
        listItems.add(
          EnhancedProcessItem(
            key: ValueKey(proc.process.pid),
            processWithHistory: proc,
          ),
        );
      }
    }

    if (activeApps.isNotEmpty) {
      listItems.add(
        UserSpaceSectionHeader(
          showSandboxedBadge: processesWithHistory.length < 5,
        ),
      );
      for (var app in activeApps) {
        listItems.add(
          UserAppItem(app: app, matchingProcess: matches[app.packageName]),
        );
      }
    }

    if (listItems.isEmpty) {
      return _buildEmptyState(theme);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => listItems[index],
        childCount: listItems.length,
      ),
    );
  }

  List<ProcessWithHistory> _filterProcesses(
    List<ProcessWithHistory> processes,
    String query,
  ) {
    return processes.where((proc) {
      return proc.process.name.toLowerCase().contains(query) ||
          proc.process.user.toLowerCase().contains(query) ||
          proc.process.pid.contains(query);
    }).toList();
  }

  List<ActiveApp> _filterActiveApps(List<ActiveApp> apps, String query) {
    return apps.where((app) {
      return app.appName.toLowerCase().contains(query) ||
          app.packageName.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildEmptyState(ThemeData theme) {
    final message = _searchQuery.isNotEmpty
        ? "No processes match your search"
        : "No process data available";

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_searchQuery.isNotEmpty)
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.colorScheme.outline,
              ),
            if (_searchQuery.isNotEmpty) const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ProcessErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Process data may be incomplete: $error",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}

class _SystemMonitorHeader extends StatefulWidget {
  final double cpuPercentage;

  const _SystemMonitorHeader({super.key, required this.cpuPercentage});

  @override
  State<_SystemMonitorHeader> createState() => _SystemMonitorHeaderState();
}

class _SystemMonitorHeaderState extends State<_SystemMonitorHeader>
    with WidgetsBindingObserver {
  final Battery _battery = Battery();
  Timer? _refreshTimer;

  int _totalRam = 0;
  int _freeRam = 0;
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  String _deviceModel = "Device";
  String _androidVersion = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initStats();
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      _refreshDynamicStats();
      _startTimer();
    }
  }

  void _startTimer() {
    _stopTimer(); // specific safety
    _refreshTimer = Timer.periodic(TaskManagerDurations.refreshInterval, (_) {
      _refreshDynamicStats();
    });
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refresh() async {
    await _refreshDynamicStats();
  }

  Future<void> _initStats() async {
    await Future.wait([_refreshDynamicStats(), _getDeviceInfo()]);
  }

  Future<void> _refreshDynamicStats() async {
    if (!mounted) return;
    try {
      const int mb = 1024 * 1024;
      // These are relatively fast calls
      final totalRam = SysInfo.getTotalPhysicalMemory() ~/ mb;
      final freeRam = SysInfo.getFreePhysicalMemory() ~/ mb;

      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      if (mounted) {
        setState(() {
          _totalRam = totalRam;
          _freeRam = freeRam;
          _batteryLevel = level;
          _batteryState = state;
        });
      }
    } catch (e) {
      debugPrint("Stats error: $e");
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (mounted) {
        setState(() {
          _deviceModel = "${androidInfo.brand} ${androidInfo.model}";
          _androidVersion = "Android ${androidInfo.version.release}";
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized, we can pass default 0s, SystemOverviewCard handles it gracefully or likely just shows 0.
    return SystemOverviewCard(
      cpuPercentage: widget.cpuPercentage,
      usedRamMb: _totalRam - _freeRam,
      totalRamMb: _totalRam,
      batteryLevel: _batteryLevel,
      isCharging: _batteryState == BatteryState.charging,
      deviceModel: _deviceModel,
      androidVersion: _androidVersion,
    );
  }
}
