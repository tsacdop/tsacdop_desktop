import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsacdop_desktop/providers/audio_state.dart';
import 'package:tsacdop_desktop/providers/downloader.dart';
import 'package:tsacdop_desktop/widgets/custom_paint.dart';

import '../storage/sqflite_db.dart';
import '../utils/extension_helper.dart';
import '../models/episodebrief.dart';

class MenuButton extends StatelessWidget {
  final Function onTap;
  final Widget child;
  const MenuButton({this.child, this.onTap, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
            height: 40.0,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: child),
      ),
    );
  }
}

class FavIcon extends StatefulWidget {
  final EpisodeBrief episode;
  FavIcon(this.episode, {Key key}) : super(key: key);

  @override
  FavIconState createState() => FavIconState();
}

class FavIconState extends State<FavIcon> {
  var _dbHelper = DBHelper();
  Future<bool> _isLiked(EpisodeBrief episode) async {
    return await _dbHelper.isLiked(episode.enclosureUrl);
  }

  Future<void> _saveLiked(EpisodeBrief episode) async {
    await _dbHelper.setLiked(episode.enclosureUrl);
    if (mounted) setState(() {});
  }

  Future<void> _setUnliked(EpisodeBrief episode) async {
    await _dbHelper.setUniked(episode.enclosureUrl);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLiked(widget.episode),
      initialData: false,
      builder: (context, snapshot) {
        return snapshot.data
            ? MenuButton(
                onTap: () => _setUnliked(widget.episode),
                child: Icon(Icons.favorite, color: Colors.red, size: 20),
              )
            : MenuButton(
                onTap: () => _saveLiked(widget.episode),
                child: Icon(Icons.favorite_border, size: 20));
      },
    );
  }
}

class DownloadIcon extends ConsumerStatefulWidget {
  final EpisodeBrief episode;
  DownloadIcon(this.episode, {Key key}) : super(key: key);

  @override
  _DownloadIconState createState() => _DownloadIconState();
}

class _DownloadIconState extends ConsumerState<DownloadIcon> {
  Future<bool> _isDownloaded() async {
    var dbHelper = DBHelper();
    return await dbHelper.isDownloaded(widget.episode.enclosureUrl);
  }

  Future<void> _deleleDonwload() async {
    await ref.read(downloadProvider.notifier).deleteDownload(widget.episode);
    if (mounted) setState(() {});
  }

  void _download() {
    ref.read(downloadProvider.notifier).download(widget.episode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isDownloaded(),
      initialData: false,
      builder: (context, snapshot) {
        if (snapshot.data)
          return MenuButton(
            onTap: _deleleDonwload,
            child: SizedBox(
              height: 20,
              width: 20,
              child: CustomPaint(
                painter: DownloadPainter(
                  color: context.accentColor,
                  fraction: 1,
                  progressColor: context.accentColor,
                  progress: 1,
                ),
              ),
            ),
          );
        return Consumer(
          builder: (context, watch, child) {
            final tasks = ref.watch(downloadProvider);
            final index = ref.read(downloadProvider).indexOf(widget.episode);
            if (index == -1)
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _download,
                  child: Container(
                    height: 50.0,
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CustomPaint(
                        painter: DownloadPainter(
                          color: Colors.grey[700],
                          fraction: 0,
                          progressColor: context.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            return tasks[index].status != DownloadTaskStatus.complete
                ? MenuButton(
                    onTap: () =>
                        ref.read(downloadProvider).cancelDownload(tasks[index]),
                    child: TweenAnimationBuilder(
                        duration: Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, fraction, child) => SizedBox(
                            height: 20,
                            width: 20,
                            child: CustomPaint(
                              painter: DownloadPainter(
                                  color: context.accentColor,
                                  fraction: fraction,
                                  progressColor: context.accentColor,
                                  progress: tasks[index].progress / 100),
                            ))))
                : MenuButton(
                    onTap: _deleleDonwload,
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CustomPaint(
                        painter: DownloadPainter(
                          color: context.accentColor,
                          fraction: 1,
                          progressColor: context.accentColor,
                          progress: 1,
                        ),
                      ),
                    ),
                  );
          },
        );
      },
    );
  }
}

class PlaylistButton extends ConsumerWidget {
  final EpisodeBrief episode;
  PlaylistButton(this.episode, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(audioState).queue;
    final url = episode.enclosureUrl;
    if (queue.contains(url))
      return MenuButton(
        onTap: () => ref.read(audioState).removeFromPlaylist(url),
        child: Icon(Icons.playlist_add_check,
            color: context.accentColor, size: 20),
      );
    return MenuButton(
      onTap: () => ref.read(audioState).addToPlaylist(url),
      child: Icon(Icons.playlist_add, size: 20),
    );
  }
}

class PlayButton extends ConsumerStatefulWidget {
  final EpisodeBrief episode;
  PlayButton(this.episode, {Key key}) : super(key: key);

  @override
  _PlayButtonState createState() => _PlayButtonState();
}

class _PlayButtonState extends ConsumerState<PlayButton> {
  Future<bool> _isDownloaded() async {
    var dbHelper = DBHelper();
    return await dbHelper.isDownloaded(widget.episode.enclosureUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            ref.watch(audioState).loadEpisode(widget.episode.enclosureUrl),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(6)),
        highlightColor: context.accentColor.withAlpha(70),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 40,
              width: 120,
              decoration: BoxDecoration(
                color: context.accentColor,
                borderRadius:
                    BorderRadius.only(bottomRight: Radius.circular(6)),
              ),
            ),
            Consumer(builder: (context, watch, child) {
              final tasks = ref.watch(downloadProvider);
              final index = ref.watch(downloadProvider).indexOf(widget.episode);
              if (index == -1) return Center();
              return tasks[index].status == DownloadTaskStatus.running
                  ? Positioned(
                      left: 0,
                      child: Container(
                          height: 40,
                          width: tasks[index].progress * 1.2,
                          color: context.accentColor),
                    )
                  : Center();
            }),
            Container(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(context.s.play,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.cloud_download, color: Colors.white)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
