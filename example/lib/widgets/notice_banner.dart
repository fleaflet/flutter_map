import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum NoticeBannerType {
  warning(
    icon: Icons.warning_rounded,
    foregroundColor: Color(0xFF410002),
    backgroundColor: Color(0xFFFFDAD6),
  ),
  recommendation(
    icon: Icons.task_alt,
    foregroundColor: Color(0xFF072100),
    backgroundColor: Color(0xFFB8F397),
  );

  const NoticeBannerType({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
}

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    required this.url,
    required this.type,
    required this.sizeTransition,
  });

  final String text;
  final String? url;
  final NoticeBannerType type;
  final double sizeTransition;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: constraints.maxWidth <= sizeTransition ? 8 : 0,
          ),
          width: double.infinity,
          color: type.backgroundColor,
          child: Flex(
            direction: constraints.maxWidth <= sizeTransition
                ? Axis.vertical
                : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type.icon,
                color: type.foregroundColor,
                size: 32,
              ),
              const SizedBox(height: 12, width: 16),
              Text(
                text,
                style: TextStyle(color: type.foregroundColor),
                textAlign: TextAlign.center,
              ),
              if (url != null) ...[
                const SizedBox(height: 0, width: 16),
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
