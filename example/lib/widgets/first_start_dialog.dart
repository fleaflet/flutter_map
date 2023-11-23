import 'package:flutter/material.dart';

class FirstStartDialog extends StatelessWidget {
  const FirstStartDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      icon: UnconstrainedBox(
        child: SizedBox.square(
          dimension: 64,
          child: Image.asset('assets/ProjectIcon.png', fit: BoxFit.fill),
        ),
      ),
      title: const Text('flutter_map Live Web Demo'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width < 750
              ? double.infinity
              : (width / (width < 1100 ? 1.5 : 2.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This is built automatically off of the latest commits to '
              "'master', so may not reflect the latest release available "
              'on pub.dev.\n'
              "This is hosted on Firebase Hosting, meaning there's limited "
              'bandwidth to share between all users, so please keep loads to a '
              'minimum.',
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "This won't be shown again",
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .inverseSurface
                        .withOpacity(0.5),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          label: const Text('OK'),
          icon: const Icon(Icons.done),
        ),
      ],
      contentPadding: const EdgeInsets.only(left: 24, top: 16, right: 24),
    );
  }
}
