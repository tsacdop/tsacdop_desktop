import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:webfeed/domain/rss_feed.dart';

import '../models/episodebrief.dart';
import '../models/podcastlocal.dart';

enum Filter { downloaded, liked, search, all }

class DBHelper {
  static Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    sqfliteFfiInit();
    final pathProvider = PathProviderLinux();
    final directory = await pathProvider.getApplicationSupportPath();
    assert(directory != null);
    var path = join(directory!, "podcasts.db");
    var databaseFactory = databaseFactoryFfi;
    var theDb = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
          version: 1, onCreate: _onCreate, onUpgrade: _onUpgrade),
    );
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    await db
        .execute("""CREATE TABLE PodcastLocal(id TEXT PRIMARY KEY,title TEXT, 
        imageUrl TEXT,rssUrl TEXT UNIQUE, primaryColor TEXT, author TEXT, 
        description TEXT, add_date INTEGER, imagePath TEXT, provider TEXT, link TEXT, 
        background_image TEXT DEFAULT '', hosts TEXT DEFAULT '',update_count INTEGER DEFAULT 0,
        episode_count INTEGER DEFAULT 0, skip_seconds INTEGER DEFAULT 0, 
        auto_download INTEGER DEFAULT 0, skip_seconds_end INTEGER DEFAULT 0,
        never_update INTEGER DEFAULT 0)""");
    await db
        .execute("""CREATE TABLE Episodes(id INTEGER PRIMARY KEY,title TEXT, 
        enclosure_url TEXT UNIQUE, enclosure_length INTEGER, pubDate TEXT, 
        description TEXT, feed_id TEXT, feed_link TEXT, milliseconds INTEGER, 
        duration INTEGER DEFAULT 0, explicit INTEGER DEFAULT 0, liked INTEGER DEFAULT 0, 
        liked_date INTEGER DEFAULT 0, downloaded TEXT DEFAULT 'ND', 
        download_date INTEGER DEFAULT 0, media_id TEXT, is_new INTEGER DEFAULT 0)""");
    await db.execute(
        """CREATE TABLE PlayHistory(id INTEGER PRIMARY KEY, title TEXT, enclosure_url TEXT,
        seconds REAL, seek_value REAL, add_date INTEGER, listen_time INTEGER DEFAULT 0)""");
    await db.execute(
        """CREATE TABLE SubscribeHistory(id TEXT PRIMARY KEY, title TEXT, rss_url TEXT UNIQUE, 
        add_date INTEGER, remove_date INTEGER DEFAULT 0, status INTEGER DEFAULT 0)""");
  }

  void _onUpgrade(Database db, int oldVersion, int newVersion) {}

  Future<List<PodcastLocal>> getPodcastLocal(List<String?> podcasts,
      {bool updateOnly = false}) async {
    var dbClient = await database;
    var podcastLocal = <PodcastLocal>[];

    for (var s in podcasts) {
      List<Map> list;
      if (updateOnly) {
        list = await dbClient.rawQuery(
            """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath , provider, 
          link ,update_count, episode_count FROM PodcastLocal WHERE id = ? AND 
          never_update = 0""", [s]);
      } else {
        list = await dbClient.rawQuery(
            """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath , provider, 
          link ,update_count, episode_count FROM PodcastLocal WHERE id = ?""",
            [s]);
      }
      if (list.length > 0) {
        podcastLocal.add(PodcastLocal(
            list.first['title'],
            list.first['imageUrl'],
            list.first['rssUrl'],
            list.first['primaryColor'],
            list.first['author'],
            list.first['id'],
            list.first['imagePath'],
            list.first['provider'],
            list.first['link'],
            upateCount: list.first['update_count'],
            episodeCount: list.first['episode_count']));
      }
    }
    return podcastLocal;
  }

  Future<List<PodcastLocal>> getPodcastLocalAll(
      {bool updateOnly = false}) async {
    var dbClient = await database;

    List<Map> list;
    if (updateOnly) {
      list = await dbClient.rawQuery(
          """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath,
         provider, link FROM PodcastLocal WHERE never_update = 0 ORDER BY 
         add_date DESC""");
    } else {
      list = await dbClient.rawQuery(
          """SELECT id, title, imageUrl, rssUrl, primaryColor, author, imagePath,
         provider, link FROM PodcastLocal ORDER BY add_date DESC""");
    }

    var podcastLocal = <PodcastLocal>[];

    for (var i in list) {
      podcastLocal.add(PodcastLocal(
          i['title'],
          i['imageUrl'],
          i['rssUrl'],
          i['primaryColor'],
          i['author'],
          i['id'],
          i['imagePath'],
          list.first['provider'],
          list.first['link']));
    }
    return podcastLocal;
  }

  Future<String?> checkPodcast(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT id FROM PodcastLocal WHERE rssUrl = ?', [url]);
    if (list.isEmpty) return '';
    return list.first['id'];
  }

  Future<int?> getPodcastCounts(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT episode_count FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) return list.first['episode_count'];
    return 0;
  }

  Future savePodcastLocal(PodcastLocal podcastLocal) async {
    var _milliseconds = DateTime.now().millisecondsSinceEpoch;
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawInsert(
          """INSERT OR IGNORE INTO PodcastLocal (id, title, imageUrl, rssUrl, 
          primaryColor, author, description, add_date, imagePath, provider, link) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
          [
            podcastLocal.id,
            podcastLocal.title,
            podcastLocal.imageUrl,
            podcastLocal.rssUrl,
            podcastLocal.primaryColor,
            podcastLocal.author,
            podcastLocal.description,
            _milliseconds,
            podcastLocal.imagePath,
            podcastLocal.provider,
            podcastLocal.link
          ]);
      await txn.rawInsert(
          """REPLACE INTO SubscribeHistory(id, title, rss_url, add_date) VALUES (?, ?, ?, ?)""",
          [
            podcastLocal.id,
            podcastLocal.title,
            podcastLocal.rssUrl,
            _milliseconds
          ]);
    });
  }

  Future<int> saveFiresideData(List<String?> list) async {
    var dbClient = await database;
    var result = await dbClient.rawUpdate(
        'UPDATE PodcastLocal SET background_image = ? , hosts = ? WHERE id = ?',
        [list[1], list[2], list[0]]);
    return result;
  }

  Future<List<String?>> getFiresideData(String id) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT background_image, hosts FROM PodcastLocal WHERE id = ?', [id]);
    if (list.isNotEmpty) {
      var data = <String?>[list.first['background_image'], list.first['hosts']];
      return data;
    }
    return ['', ''];
  }

  DateTime _parsePubDate(String? pubDate) {
    if (pubDate == null) return DateTime.now();
    DateTime date;
    var yyyy = RegExp(r'[1-2][0-9]{3}');
    var hhmm = RegExp(r'[0-2][0-9]\:[0-5][0-9]');
    var ddmmm = RegExp(r'[0-3][0-9]\s[A-Z][a-z]{2}');
    var mmDd = RegExp(r'([1-2][0-9]{3}\-[0-1]|\s)[0-9]\-[0-3][0-9]');
    // RegExp timezone
    var z = RegExp(r'(\+|\-)[0-1][0-9]00');
    var timezone = z.stringMatch(pubDate);
    var timezoneInt = 0;
    if (timezone != null) {
      if (timezone.substring(0, 1) == '-') {
        timezoneInt = int.parse(timezone.substring(1, 2));
      } else {
        timezoneInt = -int.parse(timezone.substring(1, 2));
      }
    }
    try {
      date = DateFormat('EEE, dd MMM yyyy HH:mm:ss Z', 'en_US').parse(pubDate);
    } catch (e) {
      try {
        date = DateFormat('dd MMM yyyy HH:mm:ss Z', 'en_US').parse(pubDate);
      } catch (e) {
        try {
          date = DateFormat('EEE, dd MMM yyyy HH:mm Z', 'en_US').parse(pubDate);
        } catch (e) {
          var year = yyyy.stringMatch(pubDate);
          var time = hhmm.stringMatch(pubDate);
          var month = ddmmm.stringMatch(pubDate);
          if (year != null && time != null && month != null) {
            try {
              date = DateFormat('dd MMM yyyy HH:mm', 'en_US')
                  .parse('$month $year $time');
            } catch (e) {
              date = DateTime.now();
            }
          } else if (year != null && time != null && month == null) {
            var month = mmDd.stringMatch(pubDate);
            try {
              date =
                  DateFormat('yyyy-MM-dd HH:mm', 'en_US').parse('$month $time');
            } catch (e) {
              date = DateTime.now();
            }
          } else {
            date = DateTime.now();
          }
        }
      }
    }
    date.add(Duration(hours: timezoneInt)).add(DateTime.now().timeZoneOffset);
    developer.log(date.toString());
    return date;
  }

  int _getExplicit(bool? b) {
    int result;
    if (b == true) {
      result = 1;
      return result;
    } else {
      result = 0;
      return result;
    }
  }

  bool _isXimalaya(String input) {
    var ximalaya = RegExp(r"ximalaya.com");
    return ximalaya.hasMatch(input);
  }

  String _getDescription(String content, String description, String summary) {
    if (content.length >= description.length) {
      if (content.length >= summary.length) {
        return content;
      } else {
        return summary;
      }
    } else if (description.length >= summary.length) {
      return description;
    } else {
      return summary;
    }
  }

  Future<int> savePodcastRss(RssFeed feed, String id) async {
    feed.items!.removeWhere((item) => item == null);
    var result = feed.items!.length;
    var dbClient = await database;
    String? description, url;
    for (var i = 0; i < result; i++) {
      developer.log(feed.items![i].title!);
      description = _getDescription(
          feed.items![i].content?.value ?? '',
          feed.items![i].description ?? '',
          feed.items![i].itunes!.summary ?? '');
      if (feed.items![i].enclosure != null) {
        _isXimalaya(feed.items![i].enclosure!.url!)
            ? url = feed.items![i].enclosure!.url!.split('=').last
            : url = feed.items![i].enclosure!.url;
      }

      final title = feed.items![i].itunes!.title ?? feed.items![i].title;
      final length = feed.items![i].enclosure?.length;
      final pubDate = feed.items![i].pubDate;
      final date = _parsePubDate(pubDate);
      final milliseconds = date.millisecondsSinceEpoch;
      final duration = feed.items![i].itunes!.duration?.inSeconds ?? 0;
      final explicit = _getExplicit(feed.items![i].itunes!.explicit);

      if (url != null) {
        await dbClient.transaction((txn) {
          return txn.rawInsert(
              """INSERT OR REPLACE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
              [
                title,
                url,
                length,
                pubDate,
                description,
                id,
                milliseconds,
                duration,
                explicit,
                url
              ]);
        });
      }
    }
    var list = await dbClient.rawQuery(
        'SELECT COUNT(*) as count FROM Episodes WHERE feed_id = ?', [id]);
    var countUpdate = list.first['count'];

    await dbClient.rawUpdate(
        """UPDATE PodcastLocal SET episode_count = ? WHERE id = ?""",
        [countUpdate, id]);
    return result;
  }

  Future<int> updatePodcastRss(PodcastLocal podcastLocal,
      {int removeMark = 0}) async {
    var options = BaseOptions(
      connectTimeout: 20000,
      receiveTimeout: 20000,
    );
    try {
      var response = await Dio(options).get(podcastLocal.rssUrl);
      if (response.statusCode == 200) {
        var feed = RssFeed.parse(response.data);
        String? url, description;
        feed.items!.removeWhere((item) => item == null);

        var dbClient = await database;

        var list = await dbClient.rawQuery(
            'SELECT COUNT(*) as count FROM Episodes WHERE feed_id = ?',
            [podcastLocal.id]);
        var count = list.first['count']!;
        if (removeMark == 0) {
          await dbClient.rawUpdate(
              "UPDATE Episodes SET is_new = 0 WHERE feed_id = ?",
              [podcastLocal.id]);
        }
        for (var item in feed.items!) {
          developer.log(item.title!);
          description = _getDescription(item.content!.value,
              item.description ?? '', item.itunes!.summary ?? '');

          if (item.enclosure?.url != null) {
            _isXimalaya(item.enclosure!.url!)
                ? url = item.enclosure!.url!.split('=').last
                : url = item.enclosure!.url;
          }

          final title = item.itunes!.title ?? item.title;
          final length = item.enclosure?.length ?? 0;
          final pubDate = item.pubDate;
          final date = _parsePubDate(pubDate);
          final milliseconds = date.millisecondsSinceEpoch;
          final duration = item.itunes!.duration?.inSeconds ?? 0;
          final explicit = _getExplicit(item.itunes!.explicit);

          if (url != null) {
            await dbClient.transaction((txn) async {
              await txn.rawInsert(
                  """INSERT OR IGNORE INTO Episodes(title, enclosure_url, enclosure_length, pubDate, 
                description, feed_id, milliseconds, duration, explicit, media_id, is_new) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)""",
                  [
                    title,
                    url,
                    length,
                    pubDate,
                    description,
                    podcastLocal.id,
                    milliseconds,
                    duration,
                    explicit,
                    url,
                  ]);
            });
          }
        }

        var updateList = await dbClient.rawQuery(
            'SELECT COUNT(*) as count FROM Episodes WHERE feed_id = ?',
            [podcastLocal.id]);
        var countUpdate = updateList.first['count'] as int;

        await dbClient.rawUpdate(
            """UPDATE PodcastLocal SET update_count = ?, episode_count = ? WHERE id = ?""",
            [countUpdate - (count as num), countUpdate, podcastLocal.id]);
        return countUpdate - (count as int);
      }
      return 0;
    } catch (e) {
      developer.log(e.toString(), name: 'Update podcast error');
      return -1;
    }
  }

  Future<List<EpisodeBrief>> getRssItem(String? id, int? count,
      {bool? reverse,
      Filter? filter = Filter.all,
      String? query = '',
      bool hideListened = false}) async {
    var dbClient = await database;
    var episodes = <EpisodeBrief>[];
    var list = <Map>[];
    if (hideListened) {
      if (count == -1) {
        if (reverse!) {
          switch (filter) {
            case Filter.all:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds ASC""", [id]);
              break;
            case Filter.liked:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.liked = 1 ORDER BY E.milliseconds ASC""", [id]);
              break;
            case Filter.downloaded:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.media_id != E.enclosure_url ORDER BY E.milliseconds ASC""",
                  [id]);
              break;
            case Filter.search:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.title LIKE ? ORDER BY E.milliseconds ASC""",
                  [id, '%$query%']);
              break;
            default:
          }
        } else {
          switch (filter) {
            case Filter.all:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC""", [id]);
              break;
            case Filter.liked:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.liked = 1 ORDER BY E.milliseconds DESC""", [id]);
              break;
            case Filter.downloaded:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.media_id != E.enclosure_url ORDER BY E.milliseconds DESC""",
                  [id]);
              break;
            case Filter.search:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.title LIKE ? ORDER BY E.milliseconds DESC""",
                  [id, '%$query%']);
              break;
            default:
          }
        }
      } else if (reverse!) {
        switch (filter) {
          case Filter.all:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, count]);
            break;
          case Filter.liked:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? AND E.liked = 1 GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, count]);
            break;
          case Filter.downloaded:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? AND E.enclosure_url != E.media_id 
        GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0  ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, count]);
            break;
          case Filter.search:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? AND E.title LIKE ? GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, '%$query%', count]);
            break;
          default:
        }
      } else {
        switch (filter) {
          case Filter.all:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor  FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id  
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ?  GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, count]);
            break;
          case Filter.liked:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? AND E.liked = 1 GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, count]);
            break;
          case Filter.downloaded:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? AND E.enclosure_url != E.media_id GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, count]);
            break;
          case Filter.search:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id = ? AND  E.title LIKE ? GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, '%$query%', count]);
            break;
          default:
        }
      }
    } else {
      if (count == -1) {
        if (reverse!) {
          switch (filter) {
            case Filter.all:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? ORDER BY E.milliseconds ASC""", [id]);
              break;
            case Filter.liked:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.liked = 1 ORDER BY E.milliseconds ASC""", [id]);
              break;
            case Filter.downloaded:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.media_id != E.enclosure_url ORDER BY E.milliseconds ASC""",
                  [id]);
              break;
            case Filter.search:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.title LIKE ? ORDER BY E.milliseconds ASC""",
                  [id, '%$query%']);
              break;
            default:
          }
        } else {
          switch (filter) {
            case Filter.all:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? ORDER BY E.milliseconds DESC""", [id]);
              break;
            case Filter.liked:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.liked = 1 ORDER BY E.milliseconds DESC""", [id]);
              break;
            case Filter.downloaded:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.media_id != E.enclosure_url ORDER BY E.milliseconds DESC""",
                  [id]);
              break;
            case Filter.search:
              list = await dbClient.rawQuery(
                  """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.title LIKE ? ORDER BY E.milliseconds DESC""",
                  [id, '%$query%']);
              break;
            default:
          }
        }
      } else if (reverse!) {
        switch (filter) {
          case Filter.all:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? ORDER BY E.milliseconds ASC LIMIT ?""", [id, count]);
            break;
          case Filter.liked:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.liked = 1 ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, count]);
            break;
          case Filter.downloaded:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.enclosure_url != E.media_id ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, count]);
            break;
          case Filter.search:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, 
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.title LIKE ? ORDER BY E.milliseconds ASC LIMIT ?""",
                [id, '%$query%', count]);
            break;
          default:
        }
      } else {
        switch (filter) {
          case Filter.all:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? ORDER BY E.milliseconds DESC LIMIT ?""", [id, count]);
            break;
          case Filter.liked:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.liked = 1 ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, count]);
            break;
          case Filter.downloaded:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND E.enclosure_url != E.media_id ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, count]);
            break;
          case Filter.search:
            list = await dbClient.rawQuery(
                """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.imagePath, P.title as feed_title, E.duration, E.explicit, 
        P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE P.id = ? AND  E.title LIKE ? ORDER BY E.milliseconds DESC LIMIT ?""",
                [id, '%$query%', count]);
            break;
          default:
        }
      }
    }

    if (list.isNotEmpty) {
      for (var i in list) {
        episodes.add(EpisodeBrief(
            i['title'],
            i['enclosure_url'],
            i['enclosure_length'],
            i['milliseconds'],
            i['feed_title'],
            i['primaryColor'],
            i['duration'],
            i['explicit'],
            i['imagePath'],
            i['is_new']));
      }
    }
    return episodes;
  }

  Future<List<EpisodeBrief>> getDownloadedEpisode(int? mode,
      {bool hideListened = false}) async {
    var dbClient = await database;
    var episodes = <EpisodeBrief>[];
    late List<Map> list;
    if (hideListened) {
      if (mode == 0) {
        list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.download_date, E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE E.enclosure_url != E.media_id GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.download_date DESC""",
        );
      } else if (mode == 1) {
        list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.download_date,E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE E.enclosure_url != E.media_id GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.download_date ASC""",
        );
      } else if (mode == 2) {
        list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.download_date,E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE E.enclosure_url != E.media_id GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.enclosure_length DESC""",
        );
      }
    } else //Ordered by date
    {
      if (mode == 0) {
        list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.download_date, E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        WHERE E.enclosure_url != E.media_id
        ORDER BY E.download_date DESC""",
        );
      } else if (mode == 1) {
        list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.download_date,E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        WHERE E.enclosure_url != E.media_id
        ORDER BY E.download_date ASC""",
        );
      } else if (mode == 2) {
        list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.download_date,E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        WHERE E.enclosure_url != E.media_id
        ORDER BY E.enclosure_length DESC""",
        );
      }
    }
    if (list.isNotEmpty) {
      for (var i in list) {
        episodes.add(EpisodeBrief(
            i['title'],
            i['enclosure_url'],
            i['enclosure_length'],
            i['milliseconds'],
            i['feed_title'],
            i['primaryColor'],
            i['duration'],
            i['explicit'],
            i['imagePath'],
            i['is_new'],
            downloadDate: i['download_date']));
      }
    }
    return episodes;
  }

  Future<String?> getDescription(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        'SELECT description FROM Episodes WHERE enclosure_url = ?', [url]);
    String? description = list[0]['description'];
    return description;
  }

  Future saveEpisodeDes(String url, {String? description}) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET description = ? WHERE enclosure_url = ?",
          [description, url]);
    });
  }

  Future<int?> saveMediaId(String url, String path, String id, int size) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          """UPDATE Episodes SET enclosure_length = ?, media_id = ?, 
          download_date = ?, downloaded = ? WHERE enclosure_url = ?""",
          [size, path, milliseconds, id, url]);
    });
    return count;
  }

  Future<List<EpisodeBrief>> getRecentRssItem(int top,
      {bool hideListened = false}) async {
    var dbClient = await database;
    var episodes = <EpisodeBrief>[];
    var list = <Map>[];
    if (hideListened) {
      list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ? """,
          [top]);
    } else {
      list = await dbClient.rawQuery(
          """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        ORDER BY E.milliseconds DESC LIMIT ? """, [top]);
    }
    if (list.isNotEmpty) {
      for (var i in list) {
        episodes.add(EpisodeBrief(
            i['title'],
            i['enclosure_url'],
            i['enclosure_length'],
            i['milliseconds'],
            i['feed_title'],
            i['primaryColor'],
            i['duration'],
            i['explicit'],
            i['imagePath'],
            i['is_new']));
      }
    }
    return episodes;
  }

  Future<List<EpisodeBrief>> getGroupRssItem(int top, List<String> group,
      {bool? hideListened = false}) async {
    var dbClient = await database;
    var episodes = <EpisodeBrief>[];
    if (group.length > 0) {
      var s = group.map<String>((e) => "'$e'").toList();
      var list = <Map>[];
      if (hideListened!) {
        list = await dbClient.rawQuery(
            """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE P.id in (${s.join(',')}) GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ? """,
            [top]);
      } else {
        list = await dbClient.rawQuery(
            """SELECT E.title, E.enclosure_url, E.enclosure_length, E.is_new,
        E.milliseconds, P.title as feed_title, E.duration, E.explicit, 
        P.imagePath, P.primaryColor FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        WHERE P.id in (${s.join(',')})
        ORDER BY E.milliseconds DESC LIMIT ? """, [top]);
      }
      if (list.isNotEmpty) {
        for (var i in list) {
          episodes.add(EpisodeBrief(
              i['title'],
              i['enclosure_url'],
              i['enclosure_length'],
              i['milliseconds'],
              i['feed_title'],
              i['primaryColor'],
              i['duration'],
              i['explicit'],
              i['imagePath'],
              i['is_new']));
        }
      }
    }
    return episodes;
  }

  Future setLiked(String url) async {
    var dbClient = await database;
    var milliseconds = DateTime.now().millisecondsSinceEpoch;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET liked = 1, liked_date = ? WHERE enclosure_url= ?",
          [milliseconds, url]);
    });
  }

  Future setUniked(String url) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET liked = 0 WHERE enclosure_url = ?", [url]);
    });
  }

  Future<List<EpisodeBrief>> getLikedRssItem(int i, int? sortBy,
      {bool hideListened = false}) async {
    var dbClient = await database;
    var episodes = <EpisodeBrief>[];
    var list = <Map>[];
    if (hideListened) {
      if (sortBy == 0) {
        list = await dbClient.rawQuery(
            """SELECT E.title, E.enclosure_url, E.enclosure_length, E.milliseconds, P.imagePath,
        P.title as feed_title, E.duration, E.explicit, P.primaryColor, E.is_new
        FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE E.liked = 1 GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.milliseconds DESC LIMIT ?""", [i]);
      } else {
        list = await dbClient.rawQuery(
            """SELECT E.title, E.enclosure_url, E.enclosure_length, E.milliseconds, P.imagePath,
        P.title as feed_title, E.duration, E.explicit, P.primaryColor, E.is_new
        FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        LEFT JOIN PlayHistory H ON E.enclosure_url = H.enclosure_url 
        WHERE E.liked = 1 GROUP BY E.enclosure_url HAVING SUM(H.listen_time) is null 
        OR SUM(H.listen_time) = 0 ORDER BY E.liked_date DESC LIMIT ?""", [i]);
      }
    } else {
      if (sortBy == 0) {
        list = await dbClient.rawQuery(
            """SELECT E.title, E.enclosure_url, E.enclosure_length, E.milliseconds, P.imagePath,
        P.title as feed_title, E.duration, E.explicit, P.primaryColor, E.is_new
         FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE E.liked = 1 ORDER BY E.milliseconds DESC LIMIT ?""", [i]);
      } else {
        list = await dbClient.rawQuery(
            """SELECT E.title, E.enclosure_url, E.enclosure_length, E.milliseconds, P.imagePath,
        P.title as feed_title, E.duration, E.explicit, P.primaryColor, E.is_new
        FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id
        WHERE E.liked = 1 ORDER BY E.liked_date DESC LIMIT ?""", [i]);
      }
    }
    if (list.isNotEmpty) {
      for (var i in list) {
        episodes.add(EpisodeBrief(
            i['title'],
            i['enclosure_url'],
            i['enclosure_length'],
            i['milliseconds'],
            i['feed_title'],
            i['primaryColor'],
            i['duration'],
            i['explicit'],
            i['imagePath'],
            i['is_new']));
      }
    }

    return episodes;
  }

  Future<bool> isLiked(String url) async {
    var dbClient = await database;
    var list = <Map>[];
    list = await dbClient
        .rawQuery("SELECT liked FROM Episodes WHERE enclosure_url = ?", [url]);
    if (list.isNotEmpty) {
      return list.first['liked'] == 0 ? false : true;
    }
    return false;
  }

  Future<bool> isDownloaded(String url) async {
    var dbClient = await database;
    List<Map> list = await dbClient.rawQuery(
        "SELECT id FROM Episodes WHERE enclosure_url = ? AND enclosure_url != media_id",
        [url]);
    return list.isNotEmpty;
  }

  Future<int?> delDownloaded(String url) async {
    var dbClient = await database;
    int? count;
    await dbClient.transaction((txn) async {
      count = await txn.rawUpdate(
          "UPDATE Episodes SET downloaded = 'ND', media_id = ? WHERE enclosure_url = ?",
          [url, url]);
    });
    developer.log('Deleted $url');
    return count;
  }

  Future<EpisodeBrief?> getRssItemWithUrl(String url) async {
    var dbClient = await database;
    EpisodeBrief episode;
    List<Map> list = await dbClient.rawQuery(
        """SELECT E.title, E.enclosure_url, E.enclosure_length, E.milliseconds, P.imagePath,
        P.title as feed_title, E.duration, E.explicit, P.skip_seconds, P.skip_seconds_end, 
        E.is_new, P.primaryColor, E.media_id FROM Episodes E INNER JOIN PodcastLocal P ON E.feed_id = P.id 
        WHERE E.enclosure_url = ?""", [url]);
    if (list.isEmpty) {
      return null;
    } else {
      episode = EpisodeBrief(
          list.first['title'],
          list.first['enclosure_url'],
          list.first['enclosure_length'],
          list.first['milliseconds'],
          list.first['feed_title'],
          list.first['primaryColor'],
          list.first['duration'],
          list.first['explicit'],
          list.first['imagePath'],
          list.first['is_new'],
          mediaId: list.first['media_id'],
          skipSecondsStart: list.first['skip_seconds'],
          skipSecondsEnd: list.first['skip_seconds_end']);
      return episode;
    }
  }

  Future<void> removeEpisodeNewMark(String url) async {
    var dbClient = await database;
    await dbClient.transaction((txn) async {
      await txn.rawUpdate(
          "UPDATE Episodes SET is_new = 0 WHERE enclosure_url = ?", [url]);
    });
    developer.log('remove new episode $url');
  }

  Future<String?> getFeedDescription(String? id) async {
    var dbClient = await database;
    List<Map> list = await dbClient
        .rawQuery('SELECT description FROM PodcastLocal WHERE id = ?', [id]);
    String? description = list[0]['description'];
    return description;
  }
}
