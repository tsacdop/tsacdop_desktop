import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/models/episodebrief.dart';
import 'package:tsacdop_desktop/providers/audio_state.dart';

import '../utils/extension_helper.dart';
import '../storage/sqflite_db.dart';

class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;

    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 40),
          alignment: Alignment.centerLeft,
          child: Consumer(
            builder: (context, watch, child) {
              final audio = ref.watch(audioState);
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  child,
                  SizedBox(width: 20),
                  audio.playerRunning
                      ? IconButton(
                          splashRadius: 20,
                          icon: Icon(LineIcons.stepForward),
                          onPressed: audio.playNext,
                        )
                      : IconButton(
                          splashRadius: 20,
                          onPressed: ref.read(audioState).loadPlaylist,
                          icon: Icon(Icons.play_arrow),
                        )
                ],
              );
            },
            child: Text(s.homeMenuPlaylist, style: context.textTheme.headline5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1),
        ),
        Expanded(
          child: Consumer(
            builder: (context, watch, child) {
              final audio = ref.watch(audioState);
              if (audio.queue.isNotEmpty)
                return FutureBuilder<List<EpisodeBrief>>(
                  future: _getEpisode(audio.queue),
                  initialData: [],
                  builder: (context, snapshot) {
                    var episodes = snapshot.data;
                    return !snapshot.hasData
                        ? Center()
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            padding: EdgeInsets.symmetric(
                                vertical: 20, horizontal: 30),
                            itemBuilder: (context, index) {
                              final episode = episodes[index];
                              return ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: episodes[index]
                                        .backgroudColor(context)
                                        .withOpacity(0.5),
                                    backgroundImage:
                                        episodes[index].avatarImage),
                                title: Text(
                                  episodes[index].title,
                                  style: context.textTheme.bodyText1
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  height: 50,
                                  child: Row(
                                    children: <Widget>[
                                      if (episode.explicit == 1)
                                        Container(
                                            decoration: BoxDecoration(
                                                color: Colors.red[800],
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            height: 23.0,
                                            width: 23.0,
                                            margin:
                                                EdgeInsets.only(right: 10.0),
                                            alignment: Alignment.center,
                                            child: Text('E',
                                                style: TextStyle(
                                                    color: Colors.white))),
                                      if (episode.duration != 0)
                                        _episodeTag(
                                            episode.duration == 0
                                                ? ''
                                                : s.minsCount(
                                                    episode.duration ~/ 60),
                                            Colors.cyan[300]),
                                      if (episode.enclosureLength != null)
                                        _episodeTag(
                                            episode.enclosureLength == 0
                                                ? ''
                                                : '${(episode.enclosureLength) ~/ 1000000}MB',
                                            Colors.lightBlue[300]),
                                    ],
                                  ),
                                ),
                                // trailing: ElevatedButton(
                                //   child: Text(s.play),
                                //   style: ElevatedButton.styleFrom(
                                //     elevation: 0,
                                //     splashFactory: NoSplash.splashFactory,
                                //     shadowColor: Colors.transparent,
                                //     onSurface: Colors.transparent,
                                //     primary: context.accentColor,
                                //     shape: RoundedRectangleBorder(
                                //         borderRadius: BorderRadius.circular(4)),
                                //     padding: EdgeInsets.zero,
                                //     minimumSize: Size(100, 40),
                                //   ),
                                //   onPressed: () {
                                //     context
                                //         .read(audioState)
                                //         .loadEpisode(episode.enclosureUrl);
                                //   },
                                // ),
                              );
                            },
                          );
                  },
                );
              return Center();
            },
          ),
        )
      ],
    );
  }

  Future<List<EpisodeBrief>> _getEpisode(List<String> urls) async {
    final dbHelper = DBHelper();
    List<EpisodeBrief> episodes = [];
    for (var url in urls) {
      final episode = await dbHelper.getRssItemWithUrl(url);
      episodes.add(episode);
    }
    return episodes;
  }

  Widget _episodeTag(String text, Color color) {
    if (text == '') {
      return Center();
    }
    return Container(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      height: 25.0,
      margin: EdgeInsets.only(right: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 10.0),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(fontSize: 14.0, color: Colors.black)),
    );
  }
}
