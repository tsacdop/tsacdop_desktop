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
          InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: size.height,
              width: size.width,
              child: IconTheme(
                  data: IconThemeData(
                      color: pressed
                          ? context.textColor
                          : context.textColor.withOpacity(0.4)),
                  child: icon),
            ),
          ),
          if (pressed)
            Positioned(
              left: 0,
              child: Container(
                  width: size.width / 10,
                  height: size.height,
                  color: context.accentColor),
            )
        ],
      ),
    );
  }
}
