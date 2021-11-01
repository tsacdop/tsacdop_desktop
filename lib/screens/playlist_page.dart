import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsacdop_desktop/models/episodebrief.dart';
import 'package:tsacdop_desktop/providers/audio_state.dart';

import '../utils/extension_helper.dart';
import '../storage/sqflite_db.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({Key key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Column(
      children: [
        Container(
          height: 100,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 40),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(s.homeMenuPlaylist, style: context.textTheme.headline5),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1),
        ),
        Consumer(builder: (context, watch, child) {
          final audio = watch(audioState);
          if (audio.queue.isNotEmpty)
            return Expanded(
              child: FutureBuilder<List<EpisodeBrief>>(
                future: _getEpisode(audio.queue),
                initialData: [],
                builder: (context, snapshot) {
                  var episodes = snapshot.data;
                  return !snapshot.hasData
                      ? Center()
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data.length,
                          padding: EdgeInsets.symmetric(vertical: 10),
                          itemBuilder: (context, index) {
                            final episode = episodes[index];
                            return ListTile(
                              leading: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                    backgroundColor: episodes[index]
                                        .backgroudColor(context)
                                        .withOpacity(0.5),
                                    backgroundImage:
                                        episodes[index].avatarImage),
                              ),
                              title: Text(episodes[index].title),
                              subtitle: Container(
                                padding: EdgeInsets.only(top: 5, bottom: 5),
                                height: 50,
                                child: Row(
                                  children: <Widget>[
                                    if (episode.explicit == 1)
                                      Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red[800],
                                          ),
                                          height: 25.0,
                                          width: 25.0,
                                          margin: EdgeInsets.only(right: 10.0),
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
                              trailing: ElevatedButton(
                                child: Text(s.play),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  splashFactory: NoSplash.splashFactory,
                                  shadowColor: Colors.transparent,
                                  onSurface: Colors.transparent,
                                  primary: context.accentColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(100, 40),
                                ),
                                onPressed: () {
                                  context
                                      .read(audioState)
                                      .loadEpisode(episode.enclosureUrl);
                                },
                              ),
                            );
                          },
                        );
                },
              ),
            );
          return Expanded(
            child: Center(),
          );
        })
      ],
    );
  }
}
