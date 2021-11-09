import 'dart:io';

import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'generated/l10n.dart';
import 'screens/home.dart';
import 'providers/settings_state.dart';

void main() async {
  await settingsState.initTheme();

  if (settingsState.proxy != '') {
    HttpOverrides.global = _HttpOverrides(settingsState.proxy);
  }
  DartVLC.initialize();
  runApp(ProviderScope(child: MyApp()));
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
  Widget build(BuildContext contextm, WidgetRef ref) {
    var theme = ref.watch(settings);
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
