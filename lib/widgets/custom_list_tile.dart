import 'package:flutter/material.dart';

import '../utils/extension_helper.dart';

class CustomListTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;
  final Widget child;
  const CustomListTile({Key key, this.onTap, this.selected, this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: selected ? context.accentColor : Colors.transparent,
        ),
        child: child,
      ),
    );
  }
}
