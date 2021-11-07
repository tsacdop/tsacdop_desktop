import 'package:flutter/material.dart';

import '../utils/extension_helper.dart';

class CustomListTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;
  final Widget child;
  final Widget leading;
  final Widget trailing;
  final String title;
  final String subtitle;
  final EdgeInsets padding;

  const CustomListTile({
    Key key,
    @required this.onTap,
    @required this.selected,
    this.child,
    this.padding,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
  })  : assert(child != null || leading != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.all(4.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: selected ? context.accentColor : Colors.transparent,
          ),
          child: child ?? _listItem(context, leading, title, subtitle),
        ),
      ),
    );
  }

  Widget _listItem(
      BuildContext context, Widget leading, String title, String subtitle) {
    return Row(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: leading),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  style: context.textTheme.bodyText1
                      .copyWith(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: trailing ?? Center(),
        )
      ],
    );
  }
}
