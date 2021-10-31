import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:html/parser.dart';

import 'podcasts_page.dart';
import '../providers/group_state.dart';
import '../models/episodebrief.dart';
import '../storage/key_value_storage.dart';
import '../storage/sqflite_db.dart';
import '../widgets/custom_paint.dart';
import '../widgets/episodes_grid.dart';
import '../widgets/podcast_menu.dart';
import '../models/podcastlocal.dart';
import '../utils/extension_helper.dart';

class PodcastDetail extends StatefulWidget {
  final PodcastLocal podcastLocal;
  PodcastDetail(this.podcastLocal, {Key key}) : super(key: key);

  @override
  _PodcastDetailState createState() => _PodcastDetailState();
}

class _PodcastDetailState extends State<PodcastDetail> {
  Widget _body;

  @override
  void initState() {
    _body = _EpisodeList(widget.podcastLocal);
    super.initState();
  }

  @override
  void didUpdateWidget(PodcastDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.podcastLocal != oldWidget.podcastLocal) {
      setState(() {
        _body = _EpisodeList(widget.podcastLocal);
      });
    }
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
                      padding: EdgeInsets.only(left: 40.0, right: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(podcast.title,
                              maxLines: 1,
                              style: context.textTheme.headline6
                                  .copyWith(color: Colors.white)),
                          Material(
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(podcast.author,
                                      maxLines: 1,
                                      style:
                                          TextStyle(color: Colors.grey[300])),
                                ),
                                IconButton(
                                  splashRadius: 15,
                                  icon: Icon(LineIcons.database_solid,
                                      size: 18, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _body = _EpisodeList(podcast);
                                    });
                                  },
                                ),
                                IconButton(
                                  splashRadius: 15,
                                  icon: Icon(LineIcons.cogs_solid,
                                      size: 18, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _body = _PodcastSettings(podcast);
                                    });
                                  },
                                ),
                                IconButton(
                                  splashRadius: 15,
                                  icon: Icon(LineIcons.scroll_solid,
                                      size: 18, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _body = _PodcastInfo(podcast);
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
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
        Expanded(
          child: AnimatedSwitcher(
            child: _body,
            duration: Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }
}

class _EpisodeList extends StatefulWidget {
  final PodcastLocal podcastLocal;
  const _EpisodeList(this.podcastLocal, {Key key}) : super(key: key);

  @override
  __EpisodeListState createState() => __EpisodeListState();
}

class __EpisodeListState extends State<_EpisodeList> {
  final _dbHelper = DBHelper();

  /// Episodes total count.
  int _episodeCount;

  /// Default layout.
  Layout _layout;

  int _dataCount = 0;

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
  void didUpdateWidget(_EpisodeList oldWidget) {
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
    await _dbHelper.updatePodcastRss(widget.podcastLocal);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                      borderRadius: BorderRadius.circular(4),
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
              borderRadius: BorderRadius.circular(4),
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
              borderRadius: BorderRadius.circular(4),
              child: _refresh
                  ? SizedBox(width: 30, child: RefreshLoad())
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
                borderRadius: BorderRadius.circular(4),
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
    return Column(
      children: [
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
                    builder: (context, constraint) => CustomScrollView(
                      physics: BouncingScrollPhysics(),
                      controller: _controller,
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(height: 10),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.only(right: 10),
                          sliver: EpisodesGrid(
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
                        ),
                      ],
                    ),
                  )
                : Center();
          },
        ))
      ],
    );
  }
}

class _PodcastInfo extends StatelessWidget {
  final PodcastLocal podcast;
  const _PodcastInfo(this.podcast, {Key key}) : super(key: key);

  Future<String> _getDescription() async {
    var dbHelper = DBHelper();
    var description = await dbHelper.getFeedDescription(podcast.id);
    if (description == null || description.isEmpty) {
      description = '';
      return description;
    } else {
      var doc = parse(description);
      description = parse(doc.body.text).documentElement.text;
      return description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: context.textTheme.headline6
                  .copyWith(color: context.accentColor)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Linkify(
              onOpen: (link) {
                link.url.launchUrl;
              },
              text: 'Rss link: ${podcast.rssUrl}',
              linkStyle: TextStyle(
                  color: context.accentColor,
                  height: 2,
                  decoration: TextDecoration.underline,
                  textBaseline: TextBaseline.ideographic),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _getDescription(),
              initialData: '',
              builder: (context, snapshot) {
                return Linkify(
                  onOpen: (link) {
                    link.url.launchUrl;
                  },
                  text: snapshot.data,
                  linkStyle: TextStyle(
                      color: context.accentColor,
                      height: 2,
                      decoration: TextDecoration.underline,
                      textBaseline: TextBaseline.ideographic),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastSettings extends StatefulWidget {
  final PodcastLocal podcast;

  const _PodcastSettings(this.podcast, {Key key}) : super(key: key);

  @override
  __PodcastSettingsState createState() => __PodcastSettingsState();
}

class __PodcastSettingsState extends State<_PodcastSettings> {
  List<PodcastGroup> _selectedGroups;

  @override
  void initState() {
    _selectedGroups =
        context.read(groupState.notifier).getPodcastGroup(widget.podcast.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 30),
      Container(
        height: 30.0,
        padding: EdgeInsets.symmetric(horizontal: 30),
        alignment: Alignment.centerLeft,
        child: Text(s.groups(2), style: TextStyle(color: context.accentColor)),
      ),
      Consumer(
        builder: (context, watch, child) {
          final groupList = watch(groupState);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(children: [
                for (var group in groupList)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                    child: FilterChip(
                      key: ValueKey<String>(group.id),
                      shape: RoundedRectangleBorder(),
                      label: Text(group.name),
                      selected: _selectedGroups.contains(group),
                      onSelected: (value) {
                        setState(() {
                          if (!value) {
                            _selectedGroups.remove(group);
                          } else {
                            _selectedGroups.add(group);
                          }
                        });
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      child: Text(s.save),
                      style: OutlinedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: context.accentColor,
                        shape: RoundedRectangleBorder(),
                        padding: EdgeInsets.zero,
                        minimumSize: Size(80, 58),
                      ),
                      onPressed: () async {
                        if (_selectedGroups.length > 0) {
                          await context.read(groupState).changeGroup(
                                widget.podcast.id,
                                _selectedGroups,
                              );
                          if (mounted)
                            setState(() {
                              _selectedGroups = context
                                  .read(groupState)
                                  .getPodcastGroup(widget.podcast.id);
                            });
                        }
                      },
                    ),
                  ),
                )
              ]),
            ),
          );
        },
      ),
    ]);
  }
}
