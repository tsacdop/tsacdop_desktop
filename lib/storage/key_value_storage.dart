import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsacdop_desktop/providers/group_state.dart';

const String themesKey = 'themesKey';
const String accentColorKey = 'accentColorKey';
const String realDarkKey = 'realDarkKey';
const String searchHistoryKey = 'searchHistoryKey';
const String groupsKey = 'groupsKey';
const String podcastLayoutKey = 'podcastLayoutKey';
const String hideListenedKey = 'hideListenedKey';
const String recentLayoutKey = 'recentLayoutKey';
const String favLayoutKey = 'favLayoutKey';

class KeyValueStorage {
  final String key;
  KeyValueStorage(this.key);

  Future<bool> saveInt(int setting) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, setting);
  }

  Future<int> getInt({int defaultValue = 0}) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(key) == null) await prefs.setInt(key, defaultValue);
    return prefs.getInt(key);
  }

  Future<bool> saveStringList(List<String> playList) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setStringList(key, playList);
  }

  Future<List<String>> getStringList() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getStringList(key) == null) {
      await prefs.setStringList(key, []);
    }
    return prefs.getStringList(key);
  }

  Future<bool> saveString(String string) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, string);
  }

  Future<String> getString() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      await prefs.setString(key, '');
    }
    return prefs.getString(key);
  }

  Future<bool> getBool({@required bool defaultValue}) async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == null) {
      await prefs.setBool(key, defaultValue);
    }
    var value = prefs.getBool(key);
    return value;
  }

  Future<bool> saveBool(value) async {
    var prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
  }

  Future<List<GroupEntity>> getGroups() async {
    var prefs = await SharedPreferences.getInstance();
    if (prefs.getString(key) == null) {
      var home = PodcastGroup('Home');
      await prefs.setString(
          key,
          json.encode({
            'groups': [home.toEntity().toJson()]
          }));
    }
    return json
        .decode(prefs.getString(key))['groups']
        .cast<Map<String, Object>>()
        .map<GroupEntity>(GroupEntity.fromJson)
        .toList(growable: false);
  }

  Future<bool> saveGroup(List<GroupEntity> groupList) async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.setString(
        key,
        json.encode(
            {'groups': groupList.map((group) => group.toJson()).toList()}));
  }
}
