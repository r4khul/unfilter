import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scan_progress.dart';
import '../widgets/scan_progress_widget.dart';
import '../../../apps/presentation/providers/apps_provider.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  @override
  void initState() {
    super.initState();
    // Trigger the full scan immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(installedAppsProvider.notifier).fullScan().then((_) {
        // give users a moment to see "100%"
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanStream = ref
        .watch(deviceAppsRepositoryProvider)
        .scanProgressStream;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<ScanProgress>(
        stream: scanStream,
        initialData: ScanProgress(
          status: "Initializing...",
          percent: 0,
          processedCount: 0,
          totalCount: 1, // Avoid divide by zero
        ),
        builder: (context, snapshot) {
          final progress = snapshot.data!;
          return ScanProgressWidget(progress: progress);
        },
      ),
    );
  }
}
