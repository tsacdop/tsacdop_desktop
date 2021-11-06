import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_api/searchepisodes.dart';
import '../models/service_api/searchpodcast.dart';
import '../providers/group_state.dart';
import '../service/search_api.dart';
import '../storage/key_value_storage.dart';
import '../utils/extension_helper.dart';

final selectedPodcast = StateProvider<OnlinePodcast>((ref) => null);

class SearchPage extends StatefulWidget {
  SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _query;
  FocusNode _focusNode;
  TextEditingController _controller;

  String get _input => _controller.text;

  OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(width: 2, color: color));

  @override
  void initState() {
    super.initState();
    _query = '';
    _focusNode = FocusNode();
    _controller = TextEditingController()..addListener(_reset);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(width: 20),
                    Expanded(
                      child: Stack(children: [
                        SizedBox(
                          height: 50,
                          child: TextField(
                              focusNode: _focusNode,
                              onSubmitted: _submitSearch,
                              controller: _controller,
                              decoration: InputDecoration(
                                  focusColor: context.primaryColor,
                                  hoverColor: context.primaryColor,
                                  hintText: context.s.searchEpisode,
                                  fillColor: context.primaryColor,
                                  filled: true,
                                  border: _inputBorder(context.primaryColorDark
                                      .withOpacity(0.5)),
                                  focusedBorder:
                                      _inputBorder(context.accentColor))),
                        ),
                        Positioned(
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _controller.text = '';
                                });
                              },
                              child: Container(
                                height: 50,
                                width: 50,
                                child: Icon(Icons.clear),
                              ),
                            ),
                          ),
                        )
                      ]),
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      // icon: Icon(Icons.search),
                      child: Text(s.search),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        primary: context.accentColor,
                        shadowColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        padding: EdgeInsets.zero,
                        minimumSize: Size(120, 58),
                      ),
                      onPressed: () {
                        _showResult();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1),
        ),
        if (_query != '')
          Expanded(
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _SearchResult(query: _query)),
              Expanded(
                flex: 1,
                child: Consumer(builder: (context, watch, _) {
                  final podcast = watch(selectedPodcast).state;
                  if (podcast == null) return Center();
                  return _DetailPage(podcast);
                }),
              )
            ],
          )),
        if (_query == '')
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 150,
                  child: Center(
                    child: Icon(
                      Icons.add_location_alt_rounded,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LineIcons.microphone_solid,
                        size: 30,
                        color: Colors.lightBlue,
                      ),
                      SizedBox(width: 50),
                      Icon(
                        LineIcons.broadcast_tower_solid,
                        size: 30,
                        color: Colors.deepPurple,
                      ),
                      SizedBox(width: 50),
                      Icon(
                        LineIcons.rss_square_solid,
                        size: 30,
                        color: Colors.blueGrey,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
                  child: Center(
                    child: Text(
                      context.s.searchHelper,
                      textAlign: TextAlign.center,
                      style: context.textTheme.headline6
                          .copyWith(color: Colors.grey[400]),
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  void _reset() {
    if (_input == '') {
      setState(() {
        _query = '';
      });
    }
  }

  void _submitSearch(String result) {
    setState(() => _query = result);
    if (result != '') {
      context.read(selectedPodcast).state = null;
      _saveHistory(result);
    }
  }

  void _showResult() {
    _focusNode?.unfocus();
    _submitSearch('');
    _submitSearch(_input);
  }

  Future<void> _saveHistory(String query) async {
    final storage = KeyValueStorage(searchHistoryKey);
    final history = await storage.getStringList();
    if (!history.contains(query)) {
      if (history.length >= 6) {
        history.removeLast();
      }
      history.insert(0, query);
      await storage.saveStringList(history);
    }
  }
}

class _SearchResult extends StatefulWidget {
  final String query;
  _SearchResult({this.query, Key key}) : super(key: key);

  @override
  __SearchResultState createState() => __SearchResultState();
}

class __SearchResultState extends State<_SearchResult> {
  int _limit;
  bool _loading;
  bool _loadError;
  bool _noResult;
  Future _searchFuture;
  List _podcastList = [];
  final _searchEngine = PodcastsIndexSearch();

  @override
  void initState() {
    super.initState();
    _loading = false;
    _loadError = false;
    _noResult = false;
    _limit = 10;
    _searchFuture = _getPodcatsIndexList(widget.query, limit: _limit);
  }

  @override
  void didUpdateWidget(_SearchResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query)
      setState(() {
        _loading = false;
        _loadError = false;
        _limit = 10;
        _noResult = false;
        _podcastList.clear();
        _searchFuture = _getPodcatsIndexList(widget.query, limit: _limit);
      });
  }

  Future<List<OnlinePodcast>> _getPodcatsIndexList(String searchText,
      {int limit}) async {
    var searchResult;
    try {
      searchResult = await _searchEngine.searchPodcasts(
          searchText: searchText, limit: limit);
    } catch (e) {
      log(e.toString());
      _loadError = true;
      _loading = false;
      return [];
    }
    var list = searchResult.feeds.cast();
    _podcastList = <OnlinePodcast>[
      for (var podcast in list) podcast.toOnlinePodcast
    ];
    if (_podcastList.isEmpty) _noResult = true;
    _loading = false;
    return _podcastList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (_loadError) {
          return Container(
            padding: EdgeInsets.only(top: 200),
            alignment: Alignment.topCenter,
            child: Text('Network error.',
                style: context.textTheme.headline6.copyWith(color: Colors.red)),
          );
        }
        if (_noResult) {
          return Container(
            padding: EdgeInsets.only(top: 200),
            alignment: Alignment.topCenter,
            child: Text('No result found.',
                style: context.textTheme.headline6
                    .copyWith(color: context.accentColor)),
          );
        }
        if (_podcastList.isEmpty && widget.query != null) {
          return Container(
            padding: EdgeInsets.only(top: 200),
            alignment: Alignment.topCenter,
            child: CircularProgressIndicator(),
          );
        }

        var content = snapshot.data;
        return CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return SearchResult(onlinePodcast: content[index]);
                },
                childCount: content.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
                    child: TextButton(
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ))
                          : Text(context.s.loadMore),
                      onPressed: () => _loading
                          ? null
                          : setState(
                              () {
                                _loading = true;
                                _limit += 10;
                                _searchFuture = _getPodcatsIndexList(
                                    widget.query,
                                    limit: _limit);
                              },
                            ),
                    ),
                  )
                ],
              ),
            ),
            SliverToBoxAdapter(
                child: SizedBox(
              height: 50,
              child: Center(
                child: Image(
                  image: AssetImage('assets/podcastindex.png'),
                  height: 15,
                ),
              ),
            ))
          ],
        );
      },
    );
  }
}

class SearchResult extends StatelessWidget {
  final OnlinePodcast onlinePodcast;
  SearchResult({this.onlinePodcast, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
            contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
            onTap: () {
              context.read(selectedPodcast).state = onlinePodcast;
            },
            leading: ClipRRect(
                borderRadius: BorderRadius.circular(25.0),
                child: Image(
                  height: 50.0,
                  width: 50.0,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                  image: NetworkImage(onlinePodcast.image, scale: 1),
                  loadingBuilder: (context, child, loadingProgress) =>
                      Container(
                    height: 50,
                    width: 50,
                    alignment: Alignment.center,
                    color: context.primaryColorDark,
                    child: child,
                  ),
                  errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      color: context.primaryColorDark,
                      child: Icon(Icons.error)),
                )),
            title: Text(onlinePodcast.title),
            subtitle: Text(
              onlinePodcast.publisher ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _SubscribeButton(onlinePodcast)),
      ],
    );
  }
}

class _DetailPage extends StatefulWidget {
  final OnlinePodcast onlinePodcast;
  _DetailPage(this.onlinePodcast, {Key key}) : super(key: key);

  @override
  __DetailPageState createState() => __DetailPageState();
}

class __DetailPageState extends State<_DetailPage> {
  final List<OnlineEpisode> _episodeList = [];
  Future _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _getIndexEpisodes(id: widget.onlinePodcast.rss);
  }

  @override
  void didUpdateWidget(_DetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onlinePodcast != oldWidget.onlinePodcast) {
      setState(() {
        _episodeList.clear();
        _searchFuture = _getIndexEpisodes(id: widget.onlinePodcast.rss);
      });
    }
  }

  Future<List<OnlineEpisode>> _getIndexEpisodes({String id}) async {
    var searchEngine = PodcastsIndexSearch();
    var searchResult = await searchEngine.fetchEpisode(rssUrl: id);
    var episodes = searchResult.items.cast();
    for (var episode in episodes) {
      _episodeList.add(episode.toOnlineWEpisode);
    }
    return _episodeList;
  }

  @override
  Widget build(BuildContext context) {
    final podcast = widget.onlinePodcast;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(podcast.title, style: context.textTheme.headline6),
                SizedBox(height: 20),
                Text(
                  '${widget.onlinePodcast.latestPubDate.toDate(context)}',
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(color: context.accentColor),
                ),
                Text(podcast.description, style: TextStyle(height: 2)),
                SizedBox(height: 20),
                FutureBuilder<List<OnlineEpisode>>(
                    future: _searchFuture,
                    builder: (context, snapshot) {
                      if (_episodeList.isNotEmpty) {
                        var content = snapshot.data;
                        return ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: content.length,
                          itemBuilder: (context, index) {
                            return Container(
                              color: context.primaryColor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(content[index].title,
                                      style: context.textTheme.bodyText1),
                                  Text(
                                      content[index].length == 0
                                          ? '${content[index].pubDate.toDate(context)}'
                                          : '${content[index].length.toTime} | '
                                              '${content[index].pubDate.toDate(context)}',
                                      style: TextStyle(
                                          color: context.accentColor)),
                                  SizedBox(height: 10)
                                ],
                              ),
                            );
                          },
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    })
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final OnlinePodcast podcast;
  const _SubscribeButton(this.podcast, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return OutlinedButton(
      child: Text(s.subscribe),
      style: OutlinedButton.styleFrom(
        primary: context.accentColor,
        splashFactory: NoSplash.splashFactory,
        minimumSize: Size(100, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: context.primaryColorDark,
      ),
      onPressed: () =>
          context.read(groupState.notifier).subscribePodcast(podcast),
    );
  }
}
