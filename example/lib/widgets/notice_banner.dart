import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeBanner extends StatelessWidget {
  const NoticeBanner.warning({
    super.key,
    required this.text,
    required this.url,
    required this.sizeTransition,
  })  : icon = Icons.warning_rounded,
        foregroundColor = const Color(0xFF410002),
        backgroundColor = const Color(0xFFFFDAD6);

  const NoticeBanner.recommendation({
    super.key,
    required this.text,
    required this.url,
    required this.sizeTransition,
  })  : icon = Icons.task_alt,
        foregroundColor = const Color(0xFF072100),
        backgroundColor = const Color(0xFFB8F397);

  const NoticeBanner.informational({
    super.key,
    required this.text,
    required this.url,
    required this.sizeTransition,
  })  : icon = Icons.info_outline,
        foregroundColor = const Color(0xFF072100),
        backgroundColor = Colors.lightBlueAccent;

  final String text;
  final String? url;
  final double sizeTransition;

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          color: backgroundColor,
          child: Flex(
            direction: constraints.maxWidth <= sizeTransition
                ? Axis.vertical
                : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foregroundColor, size: 32),
              const SizedBox(height: 8, width: 12),
              Text(
                text,
                style: TextStyle(color: foregroundColor),
                textAlign: TextAlign.center,
              ),
              if (url != null) ...[
                const SizedBox(height: 8, width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Learn more'),
                  onPressed: () => launchUrl(Uri.parse(url!)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
