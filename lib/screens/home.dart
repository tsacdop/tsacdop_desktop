import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/screens/player.dart';

import 'about.dart';
import 'home_tabs.dart';
import 'podcasts_page.dart';
import 'search.dart';
import 'playlist_page.dart';
import 'settings.dart';
import '../providers/downloader.dart';
import '../providers/group_state.dart';
import '../widgets/custom_button.dart';
import '../utils/extension_helper.dart';
import '../providers/settings_state.dart';

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Widget _body;
  String _selectMenu;
  OverlayEntry _overlayEntry;
  @override
  void initState() {
    _body = PodcastsPage();
    _selectMenu = 'home';
    super.initState();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject();
    var offset = renderBox.localToGlobal(Offset.zero);
    return OverlayEntry(
      builder: (constext) => Positioned(
        bottom: offset.dx + 50,
        left: offset.dy + 60,
        child: LimitedBox(
          maxHeight: 300,
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: Material(
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: context.primaryColorDark)),
                child: Consumer(builder: (context, watch, child) {
                  var tasks = watch(downloadProvider);
                  if (tasks.isEmpty)
                    return SizedBox(
                      height: 10,
                    );
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        leading: Text(tasks[index].progress),
                        title: Text(
                          task.episode.title,
                          maxLines: 1,
                        ),
                        subtitle: SizedBox(
                          height: 4,
                          child: LinearProgressIndicator(
                            value: tasks[index].progress / 100,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
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
                          SizedBox(height: 20),
                          CustomIconButton(
                            pressed: _selectMenu == 'home',
                            icon: Icon(LineIcons.home_solid),
                            onPressed: () {
                              setState(() {
                                _body = PodcastsPage();
                                _selectMenu = 'home';
                              });
                            },
                          ),
                          CustomIconButton(
                            pressed: _selectMenu == 'playlist',
                            icon: Icon(Icons.playlist_play),
                            onPressed: () {
                              setState(() {
                                _body = PlaylistPage();
                                _selectMenu = 'playlist';
                              });
                            },
                          ),
                          CustomIconButton(
                            pressed: _selectMenu == 'search',
                            icon: Icon(LineIcons.search_solid),
                            onPressed: () {
                              setState(() {
                                _body = SearchPage();
                                _selectMenu = 'search';
                              });
                            },
                          ),
                          Spacer(),
                          Consumer(builder: (context, watch, child) {
                            var tasks = watch(downloadProvider);
                            if (tasks.isNotEmpty)
                              return IconButton(
                                splashRadius: 20,
                                color: _overlayEntry != null
                                    ? context.accentColor
                                    : null,
                                icon: Icon(LineIcons.bell_solid),
                                onPressed: () {
                                  if (_overlayEntry == null) {
                                    _overlayEntry = _createOverlayEntry();
                                    Overlay.of(context).insert(_overlayEntry);
                                  } else {
                                    _overlayEntry.remove();
                                    _overlayEntry = null;
                                  }
                                  setState(() {});
                                },
                              );
                            return Center();
                          }),
                          IconButton(
                            splashRadius: 20,
                            icon: Icon(LineIcons.lightbulb),
                            onPressed: () {
                              if (context.read(settings).themeMode !=
                                  ThemeMode.dark)
                                context.read(settings).setTheme =
                                    ThemeMode.dark;
                              else {
                                context.read(settings).setTheme =
                                    ThemeMode.light;
                              }
                            },
                          ),
                          CustomIconButton(
                            pressed: _selectMenu == 'settings',
                            icon: Icon(LineIcons.cog_solid),
                            onPressed: () {
                              setState(() {
                                _body = Settings();
                                _selectMenu = 'settings';
                              });
                            },
                          ),
                          CustomIconButton(
                            pressed: _selectMenu == 'about',
                            icon: Icon(LineIcons.info_circle_solid),
                            onPressed: () {
                              setState(() {
                                _body = About();
                                _selectMenu = 'about';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      child: _body,
                      duration: Duration(milliseconds: 300),
                    ),
                  ),
                ]),
              ),
              PlayerWidget()
            ],
          ),
          Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(child: _NotificationBar())),
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
      decoration: BoxDecoration(
          color: Colors.grey[600].withOpacity(0.6),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(4.0))),
      padding: EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerRight,
      child: Text(text, maxLines: 1, style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final s = context.s;
    var refreshNotifier = watch(refreshNotification).state;
    var item = watch(currentSubscribeItem).state;
    var downloadNotifier = watch(downloadNotification).state;
    if (downloadNotifier != null) {
      return _notifierText(downloadNotifier, context);
    }
    if (refreshNotifier != null) {
      return _notifierText(refreshNotifier, context);
    }
    if (item != null)
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
    return Center();
  }
}
