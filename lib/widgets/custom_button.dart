import 'package:flutter/material.dart';

import '../utils/extension_helper.dart';

class CustomIconButton extends StatelessWidget {
  final Widget icon;
  final Size size;
  final Function() onPressed;
  final bool pressed;
  CustomIconButton(
      {this.icon, this.onPressed, Size size, this.pressed, Key key})
      : assert(pressed != null),
        this.size = size ?? Size(50, 50),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                height: size.height,
                width: size.width,
                child: IconTheme(
                    data: IconThemeData(
                        color: pressed
                            ? context.accentColor
                            : context.textColor),
                    child: icon),
              ),
            ),
          ),
          if (pressed)
            Positioned(
              left: 0,
              child: Container(
                width: size.width / 10,
                height: size.height,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4)),
                    color: context.accentColor),
              ),
            )
        ],
      ),
    );
  }
}
