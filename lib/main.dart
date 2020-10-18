import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generated/l10n.dart';
import 'screens/home.dart';
import 'providers/settings_state.dart';

void main() async {
  await settingsState.initTheme();
  HttpOverrides.global = _HttpOverrides();
  runApp(ProviderScope(child: MyApp()));
}

class _HttpOverrides extends HttpOverrides {
  @override
  String findProxyFromEnvironment(_, __) {
    return 'PROXY 127.0.0.1:7890;';
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
