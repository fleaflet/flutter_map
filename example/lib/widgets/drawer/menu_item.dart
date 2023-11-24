import 'package:flutter/material.dart';

class MenuItemWidget extends StatelessWidget {
  final String caption;
  final String routeName;
  final bool isSelected;
  final Widget? icon;

  const MenuItemWidget({
    required this.caption,
    required this.routeName,
    required String currentRoute,
    this.icon,
    super.key,
  }) : isSelected = currentRoute == routeName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(caption),
      leading: icon,
      selected: isSelected,
      onTap: () {
        if (isSelected) {
          // close drawer
          Navigator.pop(context);
          return;
        }
        Navigator.pushReplacementNamed(context, routeName);
      },
    );
  }
}
