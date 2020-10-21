import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/models/episodebrief.dart';
import 'package:tsacdop_desktop/storage/sqflite_db.dart';

import 'episodes_grid.dart';
import 'custom_paint.dart';
import '../utils/extension_helper.dart';

class LayoutButton extends StatelessWidget {
  const LayoutButton({this.layout, this.onPressed, Key key}) : super(key: key);
  final Layout layout;
  final ValueChanged<Layout> onPressed;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        if (layout == Layout.multi) {
          onPressed(Layout.one);
        } else {
          onPressed(Layout.multi);
        }
      },
      icon: layout == Layout.multi
          ? SizedBox(
              height: 10,
              width: 30,
              child: CustomPaint(
                painter: LayoutPainter(0, context.textColor),
              ),
            )
          : SizedBox(
              height: 10,
              width: 30,
              child: CustomPaint(
                painter: LayoutPainter(4, context.textTheme.bodyText1.color),
              ),
            ),
    );
  }
}

class HideListened extends StatefulWidget {
  final bool hideListened;
  HideListened({this.hideListened, Key key}) : super(key: key);
  @override
  _HideListenedState createState() => _HideListenedState();
}

class _HideListenedState extends State<HideListened>
    with SingleTickerProviderStateMixin {
  double _fraction = 0.0;
  Animation animation;
  AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _fraction = animation.value;
          });
        }
      });
    if (widget.hideListened) _controller.forward();
  }

  @override
  void didUpdateWidget(HideListened oldWidget) {
    if (oldWidget.hideListened != widget.hideListened) {
      if (widget.hideListened) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: HideListenedPainter(
            fraction: _fraction,
            color: context.textColor,
            backgroundColor: context.accentColor));
  }
}

class MultiSelectMenuBar extends StatefulWidget {
  MultiSelectMenuBar(
      {this.selectedList,
      this.selectAll,
      this.onSelectAll,
      this.onClose,
      this.onSelectAfter,
      this.onSelectBefore,
      this.hideFavorite = false,
      Key key})
      : assert(onClose != null),
        super(key: key);
  final List<EpisodeBrief> selectedList;
  final bool selectAll;
  final ValueChanged<bool> onSelectAll;
  final ValueChanged<bool> onClose;
  final ValueChanged<bool> onSelectBefore;
  final ValueChanged<bool> onSelectAfter;
  final bool hideFavorite;

  @override
  _MultiSelectMenuBarState createState() => _MultiSelectMenuBarState();
}

///Multi select menu bar.
class _MultiSelectMenuBarState extends State<MultiSelectMenuBar> {
  bool _liked;
  bool _marked;
  bool _inPlaylist;
  bool _downloaded;
  final _dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _liked = false;
    _marked = false;
    _downloaded = false;
    _inPlaylist = false;
  }

  @override
  void didUpdateWidget(MultiSelectMenuBar oldWidget) {
    if (oldWidget.selectedList != widget.selectedList) {
      setState(() {
        _liked = false;
        _marked = false;
        _downloaded = false;
        _inPlaylist = false;
      });
      super.didUpdateWidget(oldWidget);
    }
  }

  Widget _buttonOnMenu({Widget child, VoidCallback onTap}) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0), child: child),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      builder: (context, value, child) => Container(
        height: widget.selectAll == null ? 40 : 90.0 * value,
        decoration: BoxDecoration(color: context.primaryColor),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selectAll != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                                '${widget.selectedList.length} selected',
                                style: context.textTheme.headline6
                                    .copyWith(color: context.accentColor))),
                      ),
                    ),
                    Spacer(),
                    if (widget.selectedList.length == 1)
                      SizedBox(
                        height: 25,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.accentColor),
                                  primary: context.textColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100)))),
                              onPressed: () {
                                widget.onSelectBefore(true);
                              },
                              child: Text('Before')),
                        ),
                      ),
                    if (widget.selectedList.length == 1)
                      SizedBox(
                        height: 25,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.accentColor),
                                  primary: context.textColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(100)))),
                              onPressed: () {
                                widget.onSelectAfter(true);
                              },
                              child: Text('After')),
                        ),
                      ),
                    SizedBox(
                      height: 25,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.accentColor),
                                backgroundColor: widget.selectAll
                                    ? context.accentColor
                                    : null,
                                primary: widget.selectAll
                                    ? Colors.white
                                    : context.textColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(100)))),
                            onPressed: () {
                              widget.onSelectAll(!widget.selectAll);
                            },
                            child: Text('All')),
                      ),
                    )
                  ],
                ),
              Row(
                children: [
                  Spacer(),
                  if (widget.selectAll == null)
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                                '${widget.selectedList.length} selected',
                                style: context.textTheme.headline6
                                    .copyWith(color: context.accentColor))),
                      ),
                    ),
                  _buttonOnMenu(
                      child: Icon(Icons.close),
                      onTap: () => widget.onClose(true))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DotIndicator extends StatelessWidget {
  DotIndicator({this.radius = 8, this.color, Key key})
      : assert(radius > 0),
        super(key: key);
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color ?? context.accentColor));
  }
}

class RefreshLoad extends StatefulWidget {
  RefreshLoad({Key key}) : super(key: key);

  @override
  _RefreshLoadState createState() => _RefreshLoadState();
}

class _RefreshLoadState extends State<RefreshLoad>
    with SingleTickerProviderStateMixin {
  Animation _animation;
  AnimationController _controller;
  double _value;
  @override
  void initState() {
    super.initState();
    _value = 0;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _value = _animation.value;
          });
        }
      });

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
        angle: math.pi * 2 * _value,
        child: Icon(LineIcons.redo_alt_solid, size: 18));
  }
}
