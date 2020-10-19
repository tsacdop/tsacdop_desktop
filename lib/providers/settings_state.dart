import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsacdop_desktop/storage/key_value_storage.dart';

final settingsState = SettingsState();
final settings = ChangeNotifierProvider((ref) => settingsState);

class SettingsState extends ChangeNotifier {
  var _themeStorage = KeyValueStorage(themesKey);
  var _accentStorage = KeyValueStorage(accentColorKey);
  var _realDarkStorage = KeyValueStorage(realDarkKey);

  Future initTheme() async {
    await _getTheme();
    await _getAccentSetColor();
    await _getRealDark();
  }

  Color _accentSetColor;
  ThemeMode _themeMode;
  bool _realDark;

  ThemeMode get themeMode => _themeMode;

  ThemeData get lightTheme => ThemeData(
      accentColor: _accentSetColor,
      accentColorBrightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: Colors.grey[100],
      primaryColorLight: Colors.white,
      primaryColorDark: Colors.grey[300],
      dialogBackgroundColor: Colors.white,
      backgroundColor: Colors.grey[100],
      appBarTheme: AppBarTheme(
        color: Colors.grey[100],
        elevation: 0,
      ),
      textTheme: TextTheme(
        bodyText2: TextStyle(fontSize: 15.0, fontWeight: FontWeight.normal),
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
      buttonTheme: ButtonThemeData(
          height: 32,
          hoverColor: _accentSetColor.withAlpha(70),
          splashColor: _accentSetColor.withAlpha(70)));

  ThemeData get darkTheme => ThemeData.dark().copyWith(
      accentColor: _accentSetColor,
      primaryColorDark: Colors.grey[800],
      scaffoldBackgroundColor: _realDark ? Colors.black87 : Color(0XFF212121),
      primaryColor: _realDark ? Colors.black : Color(0XFF1B1B1B),
      popupMenuTheme: PopupMenuThemeData()
          .copyWith(color: _realDark ? Colors.grey[900] : null),
      appBarTheme: AppBarTheme(elevation: 0),
      buttonTheme: ButtonThemeData(height: 32),
      dialogBackgroundColor: _realDark ? Colors.grey[900] : null,
      cursorColor: _accentSetColor);

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

  set setTheme(ThemeMode mode) {
    _themeMode = mode;
    _saveTheme();
    notifyListeners();
  }

  Future _getTheme() async {
    var mode = await _themeStorage.getInt();
    _themeMode = ThemeMode.values[mode];
  }

  Future _getAccentSetColor() async {
    var colorString = await _accentStorage.getString();
    if (colorString.isNotEmpty) {
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

  Future<void> _saveAccentSetColor() async {
    await _accentStorage
        .saveString(_accentSetColor.toString().substring(10, 16));
  }

  Future<void> _saveTheme() async {
    await _themeStorage.saveInt(_themeMode.index);
  }

  Future<void> _setRealDark() async {
    await _realDarkStorage.saveBool(_realDark);
  }
}
