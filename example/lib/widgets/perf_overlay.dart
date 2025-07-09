import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PerfOverlay extends StatefulWidget {
  const PerfOverlay({super.key});

  static void showWebUnavailable(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot show performance graph overlay on web'),
          ),
        ),
      );
    }
  }

  @override
  State<PerfOverlay> createState() => _PerfOverlayState();
}

class _PerfOverlayState extends State<PerfOverlay> {
  bool showPerformanceChart = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton.outlined(
            onPressed: () => setState(
              () => showPerformanceChart = !showPerformanceChart,
            ),
            icon: const Icon(Icons.troubleshoot),
            isSelected: showPerformanceChart,
            tooltip: 'Show Performance Overlay',
          ),
        ),
        if (showPerformanceChart)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: PerformanceOverlay.allEnabled(),
          ),
      ],
    );
  }
}
