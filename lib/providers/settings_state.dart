import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';

import '../generated/l10n.dart';
import '../storage/key_value_storage.dart';

final settingsState = SettingsState();
final settings = ChangeNotifierProvider((ref) => settingsState);

class SettingsState extends ChangeNotifier {
  final _themeStorage = KeyValueStorage(themesKey);
  final _accentStorage = KeyValueStorage(accentColorKey);
  final _realDarkStorage = KeyValueStorage(realDarkKey);
  final _proxyStorage = KeyValueStorage(proxyKey);

  Future initTheme() async {
    await _getTheme();
    await _getAccentSetColor();
    await _getRealDark();
    await _getProxy();
    await _getLocale();
  }

  Color? _accentSetColor;
  ThemeMode? _themeMode;
  bool? _realDark;
  String? _proxy;
  late Locale _locale;
  String? get proxy => _proxy;

  ThemeMode? get themeMode => _themeMode;

  ThemeData get lightTheme => ThemeData(
      colorScheme: ColorScheme.light(
        primary: Colors.grey[100]!,
        secondary: _accentSetColor!,
      ),
      splashColor: Colors.transparent,
      primaryColor: Colors.grey[100],
      splashFactory: NoSplash.splashFactory,
      primaryColorLight: Colors.white,
      primaryColorDark: Colors.grey[300],
      dialogBackgroundColor: Colors.white,
      backgroundColor: Colors.grey[100],
      appBarTheme: AppBarTheme(
        color: Colors.grey[100],
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyText2: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
        bodyText1: TextStyle(
            fontSize: 18.0, fontWeight: FontWeight.w500, color: Colors.black),
        subtitle1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
        subtitle2: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[400],
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _accentSetColor,
        selectionColor: _accentSetColor,
      ),
      toggleableActiveColor: _accentSetColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          splashFactory: NoSplash.splashFactory,
          shadowColor: Colors.transparent,
          onSurface: Colors.transparent,
          primary: _accentSetColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: EdgeInsets.zero,
          minimumSize: Size(100, 40),
        ),
      ),
      buttonTheme: ButtonThemeData(
          height: 32,
          hoverColor: _accentSetColor!.withAlpha(70),
          splashColor: _accentSetColor!.withAlpha(70)));

  ThemeData get darkTheme => ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          secondary: _accentSetColor!,
          primary: Colors.grey[100]!,
        ),
        splashFactory: NoSplash.splashFactory,
        primaryColorDark: Colors.grey[800],
        scaffoldBackgroundColor:
            _realDark! ? Colors.black87 : Color(0XFF212121),
        primaryColor: _realDark! ? Colors.black : Color(0XFF1B1B1B),
        popupMenuTheme: PopupMenuThemeData()
            .copyWith(color: _realDark! ? Colors.grey[900] : null),
        appBarTheme: AppBarTheme(elevation: 0),
        buttonTheme: ButtonThemeData(height: 32),
        dialogBackgroundColor: _realDark! ? Colors.grey[900] : null,
        textTheme: TextTheme(
          bodyText2: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
          bodyText1: TextStyle(
              fontSize: 18.0, fontWeight: FontWeight.w500, color: Colors.white),
          subtitle1: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
          subtitle2: TextStyle(fontSize: 16.0, fontWeight: FontWeight.normal),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            splashFactory: NoSplash.splashFactory,
            shadowColor: Colors.transparent,
            onSurface: Colors.transparent,
            primary: _accentSetColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: EdgeInsets.zero,
            minimumSize: Size(100, 40),
          ),
        ),
      );

  set setAccentColor(Color color) {
    _accentSetColor = color;
    _saveAccentSetColor();
    notifyListeners();
  }

  set setRealDark(bool value) {
    _realDark = value;
    _setRealDark();
    notifyListeners();
  }

  set setTheme(ThemeMode? mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  set setProxy(String? proxy) {
    _proxy = proxy;
    _saveProxy();
    notifyListeners();
  }

  Future _getTheme() async {
    var mode = await _themeStorage.getInt();
    _themeMode = ThemeMode.values[mode];
  }

  Future _getAccentSetColor() async {
    var colorString = await _accentStorage.getString();
    if (colorString!.isNotEmpty) {
      var color = int.parse('FF${colorString.toUpperCase()}', radix: 16);
      _accentSetColor = Color(color).withOpacity(1.0);
    } else {
      _accentSetColor = Colors.teal[500];
      await _saveAccentSetColor();
    }
  }

  Future _getRealDark() async {
    _realDark = await _realDarkStorage.getBool(defaultValue: false);
  }

  Future _getProxy() async {
    _proxy = await _proxyStorage.getString();
  }

  Future _getLocale() async {
    var localeString = await KeyValueStorage(localeKey).getStringList();
    if (localeString.isEmpty) {
      await findSystemLocale();
      var systemLanCode;
      final list = Intl.systemLocale.split('_');
      if (list.length == 2) {
        systemLanCode = list.first;
      } else if (list.length == 3) {
        systemLanCode = '${list[0]}_${list[1]}';
      } else {
        systemLanCode = 'en';
      }
      _locale = Locale(systemLanCode);
    } else {
      _locale = Locale(localeString.first, localeString[1]);
    }
    await S.load(_locale);
  }

  Future<void> _saveAccentSetColor() async {
    await _accentStorage
        .saveString(_accentSetColor.toString().substring(10, 16));
  }

  Future<void> _saveTheme() async {
    await _themeStorage.saveInt(_themeMode!.index);
  }

  Future<void> _setRealDark() async {
    await _realDarkStorage.saveBool(_realDark);
  }

  Future<void> _saveProxy() async {
    await _proxyStorage.saveString(_proxy!);
  }
}
