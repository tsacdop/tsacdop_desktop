import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generated/l10n.dart';
import 'linux_ui/home.dart';
import 'screens/home.dart';
import 'providers/settings_state.dart';

void main() async {
  await settingsState.initTheme();

  if (settingsState.proxy != '') {
    HttpOverrides.global = _HttpOverrides(settingsState.proxy);
  }
  runApp(ProviderScope(child: MyApp()));
  // const initialSize = Size(1280, 720);
  // appWindow.minSize = initialSize;
  // appWindow.size = initialSize;
  // appWindow.alignment = Alignment.center;
  // appWindow.show();
}

class _HttpOverrides extends HttpOverrides {
  final String proxy;
  _HttpOverrides(this.proxy);
  @override
  String findProxyFromEnvironment(_, __) {
    return 'PROXY $proxy;';
  }
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext contextm, ScopedReader watch) {
    var theme = watch(settings);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tsacdop Desktop',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Home(),
    );
  }
}
