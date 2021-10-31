import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:linkify/linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'podcasts_page.dart';
import '../widgets/episode_menu.dart';
import '../storage/sqflite_db.dart';
import '../models/episodebrief.dart';
import '../utils/extension_helper.dart';

class EpisodeDetail extends StatelessWidget {
  final EpisodeBrief episode;
  const EpisodeDetail(this.episode, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      color: context.primaryColor,
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.read(openEpisode).state = null,
                  hoverColor: context.primaryColorDark.withOpacity(0.3),
                  child: Container(
                    height: 30,
                    width: 30,
                    child: Icon(Icons.keyboard_arrow_left),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child:
                        Text(episode.title, style: context.textTheme.headline5),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          s.published(DateFormat.yMMMd().format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  episode.pubDate))),
                          style: TextStyle(color: context.accentColor),
                        ),
                        SizedBox(width: 10),
                        if (episode.explicit == 1)
                          Text('E',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red))
                      ],
                    ),
                  ),
                  _ShowNote(episode)
                ],
              ),
            ),
          ),
          Container(
            height: 40,
            width: double.infinity,
            color: context.scaffoldBackgroundColor,
            child: Material(
              child: Row(
                children: [
                  FavIcon(episode),
                  DownloadIcon(episode),
                  PlaylistButton(episode),
                  Spacer(),
                  PlayButton(episode)
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ShowNote extends StatelessWidget {
  final EpisodeBrief episode;
  const _ShowNote(this.episode, {Key key}) : super(key: key);

  int _getTimeStamp(String url) {
    final time = url.substring(3).trim();
    final data = time.split(':');
    var seconds;
    if (data.length == 3) {
      seconds = int.tryParse(data[0]) * 3600 +
          int.tryParse(data[1]) * 60 +
          int.tryParse(data[2]);
    } else if (data.length == 2) {
      seconds = int.tryParse(data[0]) * 60 + int.tryParse(data[1]);
    }
    return seconds;
  }

  Future<String> _getSDescription(String url) async {
    var description;
    var dbHelper = DBHelper();
    description = (await dbHelper.getDescription(url))
        .replaceAll(RegExp(r'\s?<p>(<br>)?</p>\s?'), '')
        .replaceAll('\r', '')
        .trim();
    if (!description.contains('<')) {
      final linkList = linkify(description,
          options: LinkifyOptions(humanize: false),
          linkifiers: [UrlLinkifier(), EmailLinkifier()]);
      for (var element in linkList) {
        if (element is UrlElement) {
          description = description.replaceAll(element.url,
              '<a rel="nofollow" href = ${element.url}>${element.text}</a>');
        }
        if (element is EmailElement) {
          final address = element.emailAddress;
          description = description.replaceAll(address,
              '<a rel="nofollow" href = "mailto:$address">$address</a>');
        }
      }
      await dbHelper.saveEpisodeDes(url, description: description);
    }
    return description;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder(
      future: _getSDescription(episode.enclosureUrl),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var description = snapshot.data;
          return description.length > 0
              ? Html(
                  padding: EdgeInsets.only(left: 20.0, right: 20, bottom: 50),
                  defaultTextStyle: GoogleFonts.martel(
                      textStyle: TextStyle(
                    height: 1.8,
                  )),
                  data: description,
                  linkStyle: TextStyle(
                      color: context.accentColor,
                      textBaseline: TextBaseline.ideographic),
                  onLinkTap: (url) {
                    url.launchUrl;
                  },
                  useRichText: true,
                )
              : Container(
                  height: context.width,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image(
                        image: AssetImage('assets/shownote.png'),
                        height: 100.0,
                      ),
                      Padding(padding: EdgeInsets.all(5.0)),
                      Text(s.noShownote,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: context.textColor.withOpacity(0.5))),
                    ],
                  ),
                );
        } else {
          return Center();
        }
      },
    );
  }
}
