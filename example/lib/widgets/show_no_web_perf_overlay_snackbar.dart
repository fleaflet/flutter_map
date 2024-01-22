import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void showNoWebPerfOverlaySnackbar(BuildContext context) {
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
