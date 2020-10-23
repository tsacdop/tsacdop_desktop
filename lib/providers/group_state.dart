import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/webfeed.dart';
import 'package:uuid/uuid.dart';

import '../models/fireside_data.dart';
import '../models/service_api/searchpodcast.dart';
import '../storage/key_value_storage.dart';
import '../models/podcastlocal.dart';
import '../storage/sqflite_db.dart';

enum SubscribeState { none, start, subscribe, fetch, stop, exist, error }

final groupState = StateNotifierProvider((ref) => GroupList(ref.read));

final currentSubscribeItem = StateProvider<SubscribeItem>((ref) => null);

class GroupList extends StateNotifier<List<PodcastGroup>> {
  GroupList(this.read) : super([]) {
    _loadGroup();
  }

  final Reader read;
  final DBHelper _dbHelper = DBHelper();
  final KeyValueStorage _groupStorage = KeyValueStorage(groupsKey);

  /// Load groups from storage at start.
  Future<void> _loadGroup() async {
    final loadgroups = await _groupStorage.getGroups();
    state = loadgroups.map(PodcastGroup.fromEntity).toList();
  }

  /// Add new group.
  Future<void> addGroup(PodcastGroup podcastGroup) async {
    state = [...state, podcastGroup];
    await _saveGroup();
  }

  bool isExisted(String name) {
    for (var group in state) {
      if (group.name == name) {
        return true;
      }
    }
    return false;
  }

  /// Remove group.
  Future<void> delGroup(PodcastGroup podcastGroup) async {
    for (var podcast in podcastGroup.podcastList) {
      if (!state.first.podcastList.contains(podcast)) {
        state[0].podcastList.insert(0, podcast);
      }
    }
    state = state.where((group) => group.id == podcastGroup.id).toList();
    await _saveGroup();
  }

  List<PodcastGroup> getPodcastGroup(String id) {
    var result = <PodcastGroup>[];
    for (var group in state) {
      if (group.podcastList.contains(id)) {
        result.add(group);
      }
    }
    return result;
  }

  //Change podcast groups
  Future<void> changeGroup(String id, List<PodcastGroup> list) async {
    for (var group in state) {
      if (group.podcastList.contains(id)) {
        if (!list.contains(group))
          group.podcastList.removeWhere((groupId) => groupId == id);
      } else {
        if (list.contains(group)) group.podcastList.insert(0, id);
      }
    }
    state = [...state];
    await _saveGroup();
  }

  Future<void> _saveGroup() async {
    await _groupStorage.saveGroup(state.map((it) => it.toEntity()).toList());
  }

  Future<void> subscribePodcast(OnlinePodcast podcast) async {
    var rss = podcast.rss;
    var options = BaseOptions(
      connectTimeout: 30000,
      receiveTimeout: 90000,
    );
    final listColor = <String>[
      '388E3C',
      '1976D2',
      'D32F2F',
      '00796B',
    ];
    _setSubscribeState(podcast, SubscribeState.start);
    try {
      var response = await Dio(options).get(rss);
      RssFeed p;
      try {
        p = RssFeed.parse(response.data);
      } catch (e) {
        developer.log(e.toString(), name: 'Parse rss error');
        _setSubscribeState(podcast, SubscribeState.error);
      }

      var dir = await getApplicationSupportDirectory();
      var localPath = join(dir.path, 'images');
      final saveDir = Directory(localPath);
      var hasExisted = await saveDir.exists();
      if (!hasExisted) {
        saveDir.create();
      }
      var realUrl =
          response.redirects.isEmpty ? rss : response.realUri.toString();
      var checkUrl = await _dbHelper.checkPodcast(realUrl);
      if (checkUrl == '') {
        String imageUrl;
        img.Image thumbnail;
        try {
          var imageResponse = await Dio().get<List<int>>(p.itunes.image.href,
              options: Options(
                responseType: ResponseType.bytes,
                receiveTimeout: 90000,
              ));
          imageUrl = p.itunes.image.href;
          var image = img.decodeImage(imageResponse.data);
          thumbnail = img.copyResize(image, width: 300);
        } catch (e) {
          developer.log(e.toString(), name: 'Download image error');
          try {
            var imageResponse = await Dio().get<List<int>>(podcast.image,
                options: Options(
                  responseType: ResponseType.bytes,
                  receiveTimeout: 90000,
                ));
            imageUrl = podcast.image;
            var image = img.decodeImage(imageResponse.data);
            thumbnail = img.copyResize(image, width: 300);
          } catch (e) {
            developer.log(e.toString(), name: 'Download image error');
            try {
              var index = math.Random().nextInt(3);
              var imageResponse = await Dio().get<List<int>>(
                  "https://ui-avatars.com/api/?size=300&background="
                  "${listColor[index]}&color=fff&name=${podcast.title}&length=2&bold=true",
                  options: Options(responseType: ResponseType.bytes));
              imageUrl = "https://ui-avatars.com/api/?size=300&background="
                  "${listColor[index]}&color=fff&name=${podcast.title}&length=2&bold=true";
              thumbnail = img.decodeImage(imageResponse.data);
            } catch (e) {
              developer.log(e.toString(), name: 'Donwload image error');
              _setSubscribeState(podcast, SubscribeState.error);
              await Future.delayed(Duration(seconds: 2));
              _setSubscribeState(podcast, SubscribeState.stop);
            }
          }
        }
        var uuid = Uuid().v4();
        var imagePath = join(saveDir.path, '$uuid.png');
        File(imagePath)..writeAsBytesSync(img.encodePng(thumbnail));
        var primaryColor = await _getColor(thumbnail);
        var author = p.itunes.author ?? p.author ?? '';
        var provider = p.generator ?? '';
        var link = p.link ?? '';
        var podcastLocal = PodcastLocal(p.title, imageUrl, realUrl,
            primaryColor, author, uuid, imagePath, provider, link,
            description: p.description);

        _setSubscribeState(podcast, SubscribeState.subscribe);
        await _dbHelper.savePodcastLocal(podcastLocal);
        _subscribeNewPodcast(id: uuid);
        if (provider.contains('fireside')) {
          var data = FiresideData(uuid, link);
          try {
            await data.fatchData();
          } catch (e) {
            developer.log(e.toString(), name: 'Fatch fireside data error');
          }
        }
        await _dbHelper.savePodcastRss(p, uuid);
        _setSubscribeState(podcast, SubscribeState.fetch);
        await Future.delayed(Duration(seconds: 2));
        _setSubscribeState(podcast, SubscribeState.stop);
      } else {
        _setSubscribeState(podcast, SubscribeState.exist);
        await Future.delayed(Duration(seconds: 2));
        _setSubscribeState(podcast, SubscribeState.stop);
      }
    } catch (e) {
      developer.log(e.toString(), name: 'Download rss error');
      _setSubscribeState(podcast, SubscribeState.error);
      await Future.delayed(Duration(seconds: 2));
      _setSubscribeState(podcast, SubscribeState.stop);
    }
  }

  void _setSubscribeState(OnlinePodcast podcast, SubscribeState state) {
    read(currentSubscribeItem).state =
        SubscribeItem(podcast.rss, podcast.title, subscribeState: state);
  }

  /// Subscribe podcast from OPML.
  Future<bool> _subscribeNewPodcast(
      {String id, String groupName = 'Home'}) async {
    for (var group in state) {
      if (group.name == groupName) {
        if (group.podcastList.contains(id)) {
          return true;
        } else {
          group.podcastList.insert(0, id);
          await _saveGroup();
          await group.getPodcasts();
          return true;
        }
      }
    }
    state.add(PodcastGroup(groupName, podcastList: [id]));
    await _saveGroup();
    return true;
  }

  Future<String> _getColor(img.Image image) async {
    var color = image.getPixel(150, 150);
    var g = (color >> 16) & 0xFF;
    var r = color & 0xFF;
    var b = (color >> 8) & 0xFF;
    return [r, g, b].toString();
  }
}

class GroupEntity {
  final String name;
  final String id;
  final String color;
  final List<String> podcastList;

  GroupEntity(this.name, this.id, this.color, this.podcastList);

  Map<String, Object> toJson() {
    return {'name': name, 'id': id, 'color': color, 'podcastList': podcastList};
  }

  static GroupEntity fromJson(Map<String, Object> json) {
    var list = List<String>.from(json['podcastList']);
    return GroupEntity(json['name'] as String, json['id'] as String,
        json['color'] as String, list);
  }
}

class PodcastGroup extends Equatable {
  /// Group name.
  final String name;

  /// Group id.
  final String id;

  /// Group theme color, not used.
  final String color;

  /// Id lists of podcasts in group.
  final List<String> podcastList;

  PodcastGroup(this.name,
      {this.color = '#000000', String id, List<String> podcastList})
      : id = id ?? Uuid().v4(),
        podcastList = podcastList ?? [];

  Future<List<PodcastLocal>> getPodcasts() async {
    var dbHelper = DBHelper();
    List<PodcastLocal> podcasts = [];
    if (podcastList != []) {
      try {
        podcasts = await dbHelper.getPodcastLocal(podcastList);
      } catch (e) {
        await Future.delayed(Duration(milliseconds: 200));
        try {
          podcasts = await dbHelper.getPodcastLocal(podcastList);
        } catch (e) {
          developer.log(e.toString());
        }
      }
    }
    return podcasts;
  }

  Color getColor() {
    if (color != '#000000') {
      var colorInt = int.parse('FF${color.toUpperCase()}', radix: 16);
      return Color(colorInt).withOpacity(1.0);
    } else {
      return Colors.blue[400];
    }
  }

  GroupEntity toEntity() {
    return GroupEntity(name, id, color, podcastList);
  }

  static PodcastGroup fromEntity(GroupEntity entity) {
    return PodcastGroup(
      entity.name,
      id: entity.id,
      color: entity.color,
      podcastList: entity.podcastList,
    );
  }

  @override
  List<Object> get props => [id, name];
}

class SubscribeItem {
  ///Rss url.
  String url;

  ///Rss title.
  String title;

  /// Subscribe status.
  SubscribeState subscribeState;

  /// Podcast id.
  String id;

  ///Avatar image link.
  String imgUrl;

  ///Podcast group, default Home.
  String group;

  SubscribeItem(
    this.url,
    this.title, {
    this.subscribeState = SubscribeState.none,
    this.id = '',
    this.imgUrl = '',
    this.group = '',
  });
}
