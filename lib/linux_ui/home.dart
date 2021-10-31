import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gtk/flutter_gtk.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsacdop_desktop/screens/playlist_page.dart';
import 'package:tsacdop_desktop/screens/podcasts_page.dart';
import 'package:tsacdop_desktop/screens/search.dart';
import 'package:tsacdop_desktop/screens/settings.dart';

import '../providers/settings_state.dart';

class LinuxHome extends StatefulWidget {
  @override
  _LinuxHomeState createState() => _LinuxHomeState();
}

class _LinuxHomeState extends State<LinuxHome> {
  Widget _body;
  @override
  void initState() {
    _body = PodcastsPage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            // onPanStart: (_) => appWindow.startDragging(),
            child: AdwaitaHeaderBar(
              // onClose: () => appWindow.close(),
              leading: AdwaitaHeaderButton(
                icon: Icons.add,
                onTap: () => setState(() => _body = SearchPage()),
              ),
              center: AdwaitaViewSwitcher(
                onViewChanged: _onTabChanged,
                tabs: [
                  ViewSwitcherData(
                    icon: LineIcons.home_solid,
                    title: 'Home',
                  ),
                  ViewSwitcherData(
                    icon: Icons.playlist_play,
                    title: 'Playlist',
                  ),
                  ViewSwitcherData(
                    icon: LineIcons.info_circle_solid,
                    title: 'Settings',
                  ),
                ],
              ),
              trailling: AdwaitaHeaderButton(
                icon: LineIcons.lightbulb,
                onTap: () {
                  if (context.read(settings).themeMode != ThemeMode.dark)
                    context.read(settings).setTheme = ThemeMode.dark;
                  else {
                    context.read(settings).setTheme = ThemeMode.light;
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              child: _body,
              duration: Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(index) {
    switch (index) {
      case 0:
        setState(() {
          _body = PodcastsPage();
        });
        break;
      case 1:
        setState(() {
          _body = PlaylistPage();
        });
        break;
      case 2:
        setState(() {
          _body = Settings();
        });
        break;
      default:
        break;
    }
  }
}
