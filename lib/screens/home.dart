import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:tsacdop_desktop/screens/player.dart';

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
    _body = SearchPage();
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
                        icon: Icon(Icons.home),
                        onPressed: () {
                          setState(() {
                            _body = PodcastsPage();
                          });
                        },
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(Icons.search),
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
                        icon: Icon(Icons.settings),
                        onPressed: () {},
                      ),
                      Spacer(),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(Icons.lightbulb),
                        onPressed: () {
                          if (context.read(settings).themeMode !=
                              ThemeMode.dark)
                            context.read(settings).setTheme = ThemeMode.dark;
                          else {
                            context.read(settings).setTheme = ThemeMode.light;
                          }
                        },
                      ),
                      IconButton(
                        splashRadius: 20,
                        icon: Icon(Icons.info),
                        onPressed: () {},
                      )
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
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: _NotificationBar()),
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
  Widget importColumn(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      height: 20.0,
      alignment: Alignment.centerLeft,
      child:
          Text(text, style: TextStyle(backgroundColor: context.primaryColor)),
    );
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final s = context.s;
    var item = watch(groupState).currentSubscribeItem;
    switch (item.subscribeState) {
      case SubscribeState.start:
        return importColumn(s.notificationSubscribe(item.title), context);
      case SubscribeState.subscribe:
        return importColumn(s.notificaitonFatch(item.title), context);
      case SubscribeState.fetch:
        return importColumn(s.notificationSuccess(item.title), context);
      case SubscribeState.exist:
        return importColumn(
            s.notificationSubscribeExisted(item.title), context);
      case SubscribeState.error:
        return importColumn(s.notificationNetworkError(item.title), context);
      default:
        return Center();
    }
  }
}
