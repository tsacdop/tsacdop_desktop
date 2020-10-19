import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/models/episodebrief.dart';
import 'package:tsacdop_desktop/storage/key_value_storage.dart';
import 'package:tsacdop_desktop/storage/sqflite_db.dart';
import 'package:tsacdop_desktop/widgets/custom_paint.dart';
import 'package:tsacdop_desktop/widgets/episodes_grid.dart';
import 'package:tsacdop_desktop/widgets/podcast_menu.dart';

import 'home_tabs.dart';
import 'podcasts_page.dart';
import '../models/podcastlocal.dart';
import '../utils/extension_helper.dart';

class PodcastDetail extends StatefulWidget {
  final PodcastLocal podcastLocal;
  PodcastDetail(this.podcastLocal, {Key key}) : super(key: key);

  @override
  _PodcastDetailState createState() => _PodcastDetailState();
}

class _PodcastDetailState extends State<PodcastDetail> {
  final _dbHelper = DBHelper();

  /// Episodes total count.
  int _episodeCount;

  /// Default layout.
  Layout _layout;

  int _dataCount = 0;

  /// Load more episodes when scroll to bottom.
  bool _loadMore = false;

  /// Change sort by.
  bool _reverse = false;

  /// Filter type.
  Filter _filter = Filter.all;

  /// Query string
  String _query = '';

  ///Hide listened.
  bool _hideListened;

  ///Selected episode list.
  List<EpisodeBrief> _selectedEpisodes;

  ///Toggle for multi-select.
  bool _multiSelect;
  bool _selectAll;
  bool _selectBefore;
  bool _selectAfter;

  ScrollController _controller;

  bool _refresh;

  @override
  void initState() {
    super.initState();
    _loadMore = false;
    _reverse = false;
    _refresh = false;
    _multiSelect = false;
    _selectAll = false;
    _selectAfter = false;
    _selectBefore = false;
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PodcastDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.podcastLocal != oldWidget.podcastLocal) {
      setState(() {});
      _controller.jumpTo(0);
    }
  }

  Future<List<EpisodeBrief>> _getRssItem(PodcastLocal podcastLocal,
      {int count, bool reverse, Filter filter, String query}) async {
    var episodes = <EpisodeBrief>[];
    _episodeCount = await _dbHelper.getPodcastCounts(podcastLocal.id);
    final layoutStorage = KeyValueStorage(podcastLayoutKey);
    final hideListenedStorage = KeyValueStorage(hideListenedKey);
    final index = await layoutStorage.getInt(defaultValue: 1);
    if (_layout == null) _layout = Layout.values[index];
    if (_hideListened == null) {
      _hideListened = await hideListenedStorage.getBool(defaultValue: false);
    }
    episodes = await _dbHelper.getRssItem(podcastLocal.id, count,
        reverse: reverse,
        filter: filter,
        query: query,
        hideListened: _hideListened);
    _dataCount = episodes.length;
    return episodes;
  }

  Future<void> _refreshPodacst() async {
    setState(() {
      _refresh = true;
    });
    context.read(refreshNotification).state =
        context.s.notificationUpdate(widget.podcastLocal.title);
    var updateCount = await _dbHelper.updatePodcastRss(widget.podcastLocal);
    context.read(refreshNotification).state = null;
    if (mounted)
      setState(() {
        _refresh = false;
      });
  }

  Future<int> _getLayout() async {
    var storage = KeyValueStorage(podcastLayoutKey);
    var index = await storage.getInt(defaultValue: 1);
    return index;
  }

  Widget _customPopupMenu(
          {Widget child,
          String tooltip,
          List<PopupMenuEntry<int>> itemBuilder,
          Function(int) onSelected,
          bool clip = true}) =>
      Material(
        key: UniqueKey(),
        color: Colors.transparent,
        clipBehavior: clip ? Clip.hardEdge : Clip.none,
        child: PopupMenuButton<int>(
          color: context.primaryColorDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 1,
          tooltip: tooltip,
          child: child,
          itemBuilder: (context) => itemBuilder,
          onSelected: (value) => onSelected(value),
        ),
      );

  Widget _actionBar(BuildContext context) {
    final s = context.s;
    return Container(
        height: 30,
        child: Row(
          children: <Widget>[
            SizedBox(width: 15),
            _customPopupMenu(
                tooltip: s.filter,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: context.primaryColorDark)),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(s.filter),
                      SizedBox(width: 5),
                      Icon(
                        LineIcons.filter_solid,
                        color:
                            _filter != Filter.all ? context.accentColor : null,
                        size: 18,
                      )
                    ],
                  ),
                ),
                itemBuilder: [
                  PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: [
                        Text(s.all),
                        Spacer(),
                        if (_filter == Filter.all) DotIndicator(),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Text(s.homeTabMenuFavotite),
                        Spacer(),
                        if (_filter == Filter.liked) DotIndicator()
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Text(s.downloaded),
                        Spacer(),
                        if (_filter == Filter.downloaded) DotIndicator()
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 0:
                      if (_filter != Filter.all) {
                        setState(() {
                          _filter = Filter.all;
                          _query = '';
                        });
                      }
                      break;
                    case 1:
                      if (_filter != Filter.liked) {
                        setState(() {
                          _query = '';
                          _filter = Filter.liked;
                        });
                      }
                      break;
                    case 2:
                      if (_filter != Filter.downloaded) {
                        setState(() {
                          _query = '';
                          _filter = Filter.downloaded;
                        });
                      }
                      break;
                    default:
                  }
                }),
            Spacer(),
            Material(
              color: Colors.transparent,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: 30,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: s.homeSubMenuSortBy,
                  icon: Icon(
                    _reverse
                        ? LineIcons.hourglass_start_solid
                        : LineIcons.hourglass_end_solid,
                    color: _reverse ? context.accentColor : null,
                  ),
                  iconSize: 18,
                  onPressed: () {
                    setState(() => _reverse = !_reverse);
                  },
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              clipBehavior: Clip.hardEdge,
              child: _refresh
                  ? SizedBox(width: 30, child: _RefreshIndicator())
                  : SizedBox(
                      width: 30,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          LineIcons.redo_alt_solid,
                        ),
                        iconSize: 18,
                        onPressed: _refreshPodacst,
                      ),
                    ),
            ),
            // FutureBuilder<bool>(
            //     future: _getHideListened(),
            //     builder: (context, snapshot) {
            //       if (_hideListened == null) {
            //         _hideListened = snapshot.data;
            //       }
            //       return Material(
            //           color: Colors.transparent,
            //           clipBehavior: Clip.hardEdge,
            //           borderRadius: BorderRadius.circular(100),
            //           child: IconButton(
            //             icon: SizedBox(
            //               width: 30,
            //               height: 30,
            //               child: HideListened(
            //                 hideListened: _hideListened ?? false,
            //               ),
            //             ),
            //             onPressed: () {
            //               setState(() => _hideListened = !_hideListened);
            //             },
            //           ));
            //     }),
            FutureBuilder<int>(
                future: _getLayout(),
                builder: (context, snapshot) {
                  if (_layout == null && snapshot.data != null) {
                    _layout = Layout.values[snapshot.data];
                  }
                  return Material(
                    color: Colors.transparent,
                    clipBehavior: Clip.hardEdge,
                    child: LayoutButton(
                      layout: _layout ?? Layout.one,
                      onPressed: (layout) => setState(() {
                        _layout = layout;
                      }),
                    ),
                  );
                }),
            Material(
                color: Colors.transparent,
                clipBehavior: Clip.hardEdge,
                child: IconButton(
                  icon: SizedBox(
                    width: 20,
                    height: 10,
                    child: CustomPaint(
                        painter:
                            MultiSelectPainter(color: context.accentColor)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedEpisodes = [];
                      _multiSelect = true;
                    });
                  },
                )),
            SizedBox(width: 10)
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    var podcast = widget.podcastLocal;
    return Column(
      children: [
        Container(
          color: podcast.primaryColor.colorizedark(),
          height: 120,
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.read(openPodcast).state = null,
                            hoverColor:
                                context.primaryColorDark.withOpacity(0.3),
                            child: Container(
                              height: 30,
                              width: 30,
                              child: Icon(Icons.keyboard_arrow_left,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(podcast.title,
                              maxLines: 2,
                              style: context.textTheme.headline6
                                  .copyWith(color: Colors.white)),
                          Text(podcast.author,
                              maxLines: 1,
                              style: TextStyle(color: Colors.grey[300])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: Image.file(File("${widget.podcastLocal.imagePath}")),
              ),
            ],
          ),
        ),
        Container(
          height: 50,
          color: context.primaryColor,
          child: _actionBar(context),
        ),
        Expanded(
            child: FutureBuilder<List<EpisodeBrief>>(
          future: _getRssItem(widget.podcastLocal,
              count: -1, reverse: _reverse, filter: _filter, query: _query),
          builder: (context, snapshot) {
            return snapshot.hasData
                ? LayoutBuilder(
                    builder: (context, constraint) => Scrollbar(
                      child: CustomScrollView(
                        physics: BouncingScrollPhysics(),
                        controller: _controller,
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(height: 10),
                          ),
                          EpisodesGrid(
                            episodes: snapshot.data,
                            showFavorite: true,
                            showNumber: _filter == Filter.all && !_hideListened
                                ? true
                                : false,
                            layout: _layout,
                            reverse: _reverse,
                            episodeCount: _episodeCount,
                            initNum: 0,
                            width: constraint.maxWidth,
                            multiSelect: _multiSelect,
                            selectedList: _selectedEpisodes ?? [],
                            onSelect: (value) => setState(
                              () {
                                _selectAll = false;
                                _selectBefore = false;
                                _selectAfter = false;
                                _selectedEpisodes = value;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center();
          },
        ))
      ],
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

class _RefreshIndicator extends StatefulWidget {
  _RefreshIndicator({Key key}) : super(key: key);

  @override
  __RefreshIndicatorState createState() => __RefreshIndicatorState();
}

class __RefreshIndicatorState extends State<_RefreshIndicator>
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
