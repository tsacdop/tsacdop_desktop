import 'package:flutter/material.dart';

import '../utils/extension_helper.dart';

class ColorPicker extends StatefulWidget {
  final ValueChanged<Color>? onColorChanged;
  ColorPicker({Key? key, this.onColorChanged}) : super(key: key);
  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker>
    with SingleTickerProviderStateMixin {
  TabController? _controller;
  int? _index;
  @override
  void initState() {
    super.initState();
    _index = 0;
    _controller = TabController(length: Colors.primaries.length, vsync: this)
      ..addListener(() {
        setState(() => _index = _controller!.index);
      });
  }

  Widget _colorCircle(Color color) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onColorChanged!(color),
          child: Container(
            decoration: BoxDecoration(
                border: color == context.accentColor
                    ? Border.all(color: Colors.grey[400]!, width: 4)
                    : null,
                color: color),
          ),
        ),
      );

  List<Widget> _accentList(MaterialAccentColor color) => [
        _colorCircle(color.shade100),
        _colorCircle(color.shade200),
        _colorCircle(color.shade400),
        _colorCircle(color.shade700)
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 40,
            color: context.primaryColorDark,
            child: TabBar(
              labelPadding: EdgeInsets.symmetric(horizontal: 10),
              controller: _controller,
              indicatorColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              isScrollable: true,
              tabs: Colors.primaries
                  .map<Widget>((color) => Tab(
                        child: Container(
                          height: 20,
                          width: 40,
                          decoration: BoxDecoration(
                              border: Colors.primaries.indexOf(color) == _index
                                  ? Border.all(
                                      color: Colors.grey[400]!, width: 2)
                                  : null,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
                              color: color),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              physics: const ClampingScrollPhysics(),
              key: UniqueKey(),
              controller: _controller,
              children: Colors.primaries
                  .map<Widget>((color) => GridView.count(
                        primary: false,
                        padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        crossAxisCount: 5,
                        children: <Widget>[
                          _colorCircle(color.shade100),
                          _colorCircle(color.shade200),
                          _colorCircle(color.shade300),
                          _colorCircle(color.shade400),
                          _colorCircle(color.shade500),
                          _colorCircle(color.shade600),
                          _colorCircle(color.shade700),
                          _colorCircle(color.shade800),
                          _colorCircle(color.shade900),
                          ...color == Colors.red
                              ? _accentList(Colors.redAccent)
                              : color == Colors.pink
                                  ? _accentList(Colors.pinkAccent)
                                  : color == Colors.deepOrange
                                      ? _accentList(Colors.deepOrangeAccent)
                                      : color == Colors.orange
                                          ? _accentList(Colors.orangeAccent)
                                          : color == Colors.amber
                                              ? _accentList(Colors.amberAccent)
                                              : color == Colors.yellow
                                                  ? _accentList(
                                                      Colors.yellowAccent)
                                                  : color == Colors.lime
                                                      ? _accentList(
                                                          Colors.limeAccent)
                                                      : color ==
                                                              Colors.lightGreen
                                                          ? _accentList(Colors
                                                              .lightGreenAccent)
                                                          : color ==
                                                                  Colors.green
                                                              ? _accentList(Colors
                                                                  .greenAccent)
                                                              : color ==
                                                                      Colors
                                                                          .teal
                                                                  ? _accentList(
                                                                      Colors
                                                                          .tealAccent)
                                                                  : color ==
                                                                          Colors
                                                                              .cyan
                                                                      ? _accentList(
                                                                          Colors
                                                                              .cyanAccent)
                                                                      : color ==
                                                                              Colors.lightBlue
                                                                          ? _accentList(Colors.lightBlueAccent)
                                                                          : color == Colors.blue
                                                                              ? _accentList(Colors.blueAccent)
                                                                              : color == Colors.indigo
                                                                                  ? _accentList(Colors.indigoAccent)
                                                                                  : color == Colors.purple
                                                                                      ? _accentList(Colors.purpleAccent)
                                                                                      : color == Colors.deepPurple
                                                                                          ? _accentList(Colors.deepPurpleAccent)
                                                                                          : []
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
