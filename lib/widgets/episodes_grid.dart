import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/podcasts_page.dart';
import '../models/episodebrief.dart';
import '../utils/extension_helper.dart';
import 'episode_menu.dart';

enum Layout { multi, one }
final hoverEpisode = StateProvider<EpisodeBrief>((ref) => null);

class EpisodesGrid extends ConsumerWidget {
  final List<EpisodeBrief> episodes;
  final bool showFavorite;
  final bool showDownload;
  final bool showNumber;
  final int episodeCount;
  final Layout layout;
  final bool reverse;
  final bool multiSelect;
  final double width;
  final ValueChanged<List<EpisodeBrief>> onSelect;
  final List<EpisodeBrief> selectedList;

  /// Count of animation items.
  final int initNum;

  EpisodesGrid(
      {Key key,
      @required this.episodes,
      this.initNum = 12,
      this.showDownload = false,
      this.showFavorite = false,
      this.showNumber = false,
      this.episodeCount = 0,
      this.layout = Layout.multi,
      this.width,
      this.reverse,
      this.multiSelect = false,
      this.onSelect,
      this.selectedList})
      : super(key: key);

  final List<EpisodeBrief> _selectedList = [];

  /// Episode title widget.
  Widget _title(EpisodeBrief episode) => Container(
        alignment:
            layout == Layout.one ? Alignment.centerLeft : Alignment.topLeft,
        padding: EdgeInsets.only(top: 2.0),
        child: Text(
          episode.title,
          maxLines: layout == Layout.one ? 1 : 3,
          overflow:
              layout == Layout.one ? TextOverflow.ellipsis : TextOverflow.fade,
        ),
      );

  Widget _pubDate(BuildContext context, {EpisodeBrief episode, Color color}) =>
      Text(
        episode.pubDate.toDate(context),
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontStyle: FontStyle.italic),
      );

  /// Count indicator widget.
  Widget _numberIndicater(BuildContext context, {int index, Color color}) =>
      showNumber
          ? Container(
              alignment: Alignment.center,
              child: Text(
                reverse
                    ? (index + 1).toString()
                    : (episodeCount - index).toString(),
                style: GoogleFonts.teko(
                  textStyle: TextStyle(
                    fontSize: 30,
                    color: color,
                  ),
                ),
              ),
            )
          : Center();

  /// Circel avatar widget.
  Widget _circleImage(BuildContext context,
          {EpisodeBrief episode,
          Color color,
          bool hideAvatar,
          double radius,
          bool showNum,
          int index}) =>
      Container(
        height: radius,
        width: radius,
        child: hideAvatar
            ? Center()
            : CircleAvatar(
                backgroundColor: color.withOpacity(0.8),
                backgroundImage: showNum ? null : episode.avatarImage,
                child: showNum
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: _numberIndicater(context,
                            index: index, color: Colors.white),
                      )
                    : Center(),
              ),
      );

  /// New indicator widget.
  Widget _isNewIndicator(EpisodeBrief episode) => episode.isNew == 1
      ? Container(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text('New',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
        )
      : Center();
  Widget _infoWidget(int index) {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          if (episodes[index].duration != 0)
            Align(
              alignment: Alignment.center,
              child: Text(
                episodes[index].duration.toTime,
              ),
            ),
          if (episodes[index].duration != 0 &&
              episodes[index].enclosureLength != null &&
              episodes[index].enclosureLength != 0)
            Text(
              '|',
              style: TextStyle(),
            ),
          if (episodes[index].enclosureLength != null &&
              episodes[index].enclosureLength != 0)
            Align(
              alignment: Alignment.center,
              child: Text(
                '${(episodes[index].enclosureLength) ~/ 1000000}MB',
              ),
            ),
        ]);
  }

  Widget _hoverMenuBat(int index, {double width}) {
    return Consumer(
      builder: (context, ref, child) {
        final episode = ref.watch(hoverEpisode);
        if (episode != null && episode == episodes[index])
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final episode = episodes[index];
              return width == null
                  ? Container(
                      decoration: BoxDecoration(
                          color: context.primaryColorDark,
                          borderRadius: BorderRadius.circular(6)),
                      height: 40 * value,
                      child: SingleChildScrollView(
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FavIcon(episode),
                              DownloadIcon(episode),
                              PlaylistButton(episode),
                              PlayButton(episode)
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: context.primaryColorDark,
                      height: 40 * value,
                      width: width,
                      child: SingleChildScrollView(
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FavIcon(episode),
                              Spacer(),
                              DownloadIcon(episode),
                              // PlayButton(episode)
                            ],
                          ),
                        ),
                      ),
                    );
            },
          );
        return Center();
      },
    );
  }

  Widget _layoutOneCard(BuildContext context,
      {int index,
      Color color,
      bool isLiked,
      bool showNum,
      bool isDownloaded,
      bool hideAvatar}) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Center(
                  child: _circleImage(context,
                      episode: episodes[index],
                      color: color,
                      hideAvatar: hideAvatar,
                      showNum: showNumber,
                      index: index,
                      radius: 60),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Text(episodes[index].feedTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          _isNewIndicator(episodes[index]),
                          // _downloadIndicater(context,
                          //     episode: episodes[index], isDownloaded: isDownloaded),
                        ],
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Align(
                            alignment: Alignment.topLeft,
                            child: _title(episodes[index]))),
                    Expanded(
                      flex: 1,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            if (episodes[index].duration != 0)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  episodes[index].duration.toTime,
                                ),
                              ),
                            if (episodes[index].duration != 0 &&
                                episodes[index].enclosureLength != null &&
                                episodes[index].enclosureLength != 0)
                              Text(
                                '|',
                                style: TextStyle(),
                              ),
                            if (episodes[index].enclosureLength != null &&
                                episodes[index].enclosureLength != 0)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${(episodes[index].enclosureLength) ~/ 1000000}MB',
                                ),
                              ),
                            SizedBox(width: 4),
                            if (isLiked)
                              Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                            Spacer(),
                            _pubDate(context,
                                episode: episodes[index],
                                color: context.textColor)
                          ]),
                    )
                  ],
                ),
              ),
              SizedBox(width: 20)
            ],
          ),
        ),
        _hoverMenuBat(index)
      ],
    );
  }

  Widget _episodeCard(BuildContext context,
      {int index,
      Color color,
      bool isLiked,
      bool isDownloaded,
      bool showNum,
      bool hideAvatar}) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _circleImage(context,
                        episode: episodes[index],
                        color: color,
                        radius: 40,
                        showNum: false,
                        hideAvatar: hideAvatar),
                    Spacer(),
                    //_isNewIndicator(episodes[index]),
                    // _downloadIndicater(context,
                    //     episode: episodes[index], isDownloaded: isDownloaded),
                    _numberIndicater(context, index: index, color: color)
                  ],
                ),
              ),
              Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _infoWidget(index),
                      _title(episodes[index]),
                    ],
                  )),
              Expanded(
                flex: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _pubDate(context, episode: episodes[index], color: color),
                    Padding(
                      padding: EdgeInsets.all(1),
                    ),
                    if (isLiked)
                      Icon(
                        Icons.favorite,
                        color: Colors.red,
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
        _hoverMenuBat(index, width: width)
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = math.max(width ~/ 180, 3);
    return layout == Layout.one
        ? SliverList(
            delegate:
                SliverChildBuilderDelegate((BuildContext context, int index) {
              final c = episodes[index].backgroudColor(context);
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onHover: (value) {
                    if (value && ref.read(hoverEpisode.notifier).state == null)
                      ref.read(hoverEpisode.notifier).state = episodes[index];
                    else
                      ref.read(hoverEpisode.notifier).state = null;
                  },
                  onTap: () =>
                      ref.read(openEpisode.notifier).state = episodes[index],
                  child: Container(
                    height: 120,
                    child: _layoutOneCard(context,
                        index: index,
                        isLiked: false,
                        isDownloaded: false,
                        showNum: showNumber,
                        color: c,
                        hideAvatar: false),
                  ),
                ),
              );
            }, childCount: episodes.length),
          )
        : SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: 1,
              crossAxisCount: count,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final c = episodes[index].backgroudColor(context);
                return InkWell(
                  onHover: (value) {
                    if (value && ref.read(hoverEpisode.notifier).state == null)
                      ref.read(hoverEpisode.notifier).state = episodes[index];
                    else
                      ref.read(hoverEpisode.notifier).state = null;
                  },
                  onTap: () =>
                      ref.read(openEpisode.notifier).state = episodes[index],
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        color: context.primaryColor),
                    child: _episodeCard(context,
                        index: index,
                        isLiked: false,
                        isDownloaded: false,
                        showNum: showNumber,
                        color: c,
                        hideAvatar: false),
                  ),
                );
              },
              childCount: episodes.length,
            ),
          );
  }
}
