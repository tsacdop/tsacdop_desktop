import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/screens/player.dart';

import 'about.dart';
import 'home_tabs.dart';
import 'podcasts_page.dart';
import 'search.dart';
import '../providers/group_state.dart';
import '../utils/extension_helper.dart';
import '../providers/settings_state.dart';

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
          Expanded(
            child: Row(children: [
              Container(
                width: 50,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: context.primaryColor,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Image.asset('assets/logo.png'),
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(LineIcons.home_solid),
                        onPressed: () {
                          setState(() {
                            _body = PodcastsPage();
                          });
                        },
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(LineIcons.search_solid),
                        onPressed: () {
                          setState(() {
                            _body = SearchPage();
                          });
                        },
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(Icons.playlist_play),
                        onPressed: () {},
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(LineIcons.info_circle_solid),
                        onPressed: () {
                          setState(() {
                            _body = About();
                          });
                        },
                      ),
                      Spacer(),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(LineIcons.cog_solid),
                        onPressed: () {},
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(LineIcons.lightbulb),
                        onPressed: () {
                          if (context.read(settings).themeMode !=
                              ThemeMode.dark)
                            context.read(settings).setTheme = ThemeMode.dark;
                          else {
                            context.read(settings).setTheme = ThemeMode.light;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      child: _body,
                      duration: Duration(milliseconds: 300),
                    ),
                    Positioned(left: 0, bottom: 0, child: _NotificationBar()),
                  ],
                ),
              ),
            ]),
          ),
          PlayerWidget()
        ],
      ),
    );
  }
}

class _NotificationBar extends ConsumerWidget {
  const _NotificationBar({Key key}) : super(key: key);
  Widget _notifierText(String text, BuildContext context) {
    return Container(
      height: 30,
      color: Colors.grey[600],
      padding: EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Text(text, maxLines: 1, style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final s = context.s;
    var refreshNotifier = watch(refreshNotification).state;
    var item = watch(groupState).currentSubscribeItem;
    if (refreshNotifier != null) {
      return _notifierText(refreshNotifier, context);
    }
    switch (item.subscribeState) {
      case SubscribeState.start:
        return _notifierText(s.notificationSubscribe(item.title), context);
      case SubscribeState.subscribe:
        return _notifierText(s.notificaitonFatch(item.title), context);
      case SubscribeState.fetch:
        return _notifierText(s.notificationSuccess(item.title), context);
      case SubscribeState.exist:
        return _notifierText(
            s.notificationSubscribeExisted(item.title), context);
      case SubscribeState.error:
        return _notifierText(s.notificationNetworkError(item.title), context);
      default:
        return Center();
    }
  }
}
