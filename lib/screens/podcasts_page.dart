import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resizable_widget/resizable_widget.dart';

import '../models/episodebrief.dart';
import '../models/podcastlocal.dart';
import '../providers/group_state.dart';
import '../utils/extension_helper.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_list_tile.dart';
import 'episode_detail.dart';
import 'home_tabs.dart';
import 'podcast_detail.dart';

final openPodcast = StateProvider<PodcastLocal?>((ref) => null);
final openEpisode = StateProvider<EpisodeBrief?>((ref) => null);

class PodcastsPage extends ConsumerWidget {
  PodcastsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: ResizableWidget(
        isHorizontalSeparator: false, // optional
        isDisabledSmartHide: false, // optional
        separatorColor: context.primaryColorDark, // optional
        separatorSize: 1,
        percentages: [0.3, 0.7],
        children: [
          _PodcastGroup(),
          Consumer(
            builder: (context, watch, _) {
              final podcast = ref.watch(openPodcast);
              final episode = ref.watch(openEpisode);
              if (episode != null)
                return EpisodeDetail(episode);
              else if (podcast != null) return PodcastDetail(podcast);
              return HomeTabs();
            },
          ),
        ],
      ),
    );
  }
}

class _PodcastGroup extends ConsumerStatefulWidget {
  const _PodcastGroup({Key? key}) : super(key: key);

  @override
  __PodcastGroupState createState() => __PodcastGroupState();
}

class __PodcastGroupState extends ConsumerState<_PodcastGroup> {
  int? _groupIndex;
  @override
  void initState() {
    super.initState();
    _groupIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, child) {
      final groupList = ref.watch(groupState);
      if (groupList.isEmpty) {
        return Center();
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8.0),
            child: ListTile(
              leading: MyDropdownButton<int>(
                hint: Center(),
                underline: Center(),
                elevation: 0,
                displayItemCount: 5,
                value: _groupIndex,
                dropdownColor: context.primaryColorDark,
                onChanged: (value) {
                  setState(() => _groupIndex = value);
                },
                items: [
                  for (var group in groupList)
                    DropdownMenuItem<int>(
                        value: groupList.indexOf(group),
                        child: Text(group.name ?? ''))
                ],
              ),
              trailing: IconButton(
                splashRadius: 20,
                icon: Icon(Icons.add),
                onPressed: () {
                  showGeneralDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierLabel: MaterialLocalizations.of(context)
                          .modalBarrierDismissLabel,
                      barrierColor: Colors.transparent,
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (context, animaiton, secondaryAnimation) =>
                          AddGroup());
                },
              ),
            ),
          ),
          FutureBuilder<List<PodcastLocal>>(
            future: groupList[_groupIndex!].getPodcasts(),
            initialData: [],
            builder: (context, snapshot) {
              if (snapshot.data!.isEmpty) return Center();
              return Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var podcast in snapshot.data!)
                      _podcastListTile(context, podcast)
                  ],
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _podcastListTile(BuildContext context, PodcastLocal podcast) =>
      Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(openPodcast) == podcast;
          return CustomListTile(
            selected: selected,
            onTap: () {
              ref.watch(openEpisode.notifier).state = null;
              ref.watch(openPodcast.notifier).state = podcast;
            },
            child: Row(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: CircleAvatar(
                      backgroundColor:
                          podcast.backgroudColor(context).withOpacity(0.5),
                      backgroundImage: podcast.avatarImage),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(podcast.title!,
                          maxLines: 1,
                          style: context.textTheme.bodyText1!
                              .copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        podcast.author!,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class AddGroup extends ConsumerStatefulWidget {
  @override
  _AddGroupState createState() => _AddGroupState();
}

class _AddGroupState extends ConsumerState<AddGroup> {
  TextEditingController? _controller;
  String? _newGroup;
  int? _error;

  @override
  void initState() {
    super.initState();
    _error = 0;
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s!;
    return Stack(
      children: [
        Positioned(
          top: 20,
          left: 40,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            titlePadding: EdgeInsets.all(20),
            actionsPadding: EdgeInsets.all(4),
            actions: <Widget>[
              TextButton(
                style: OutlinedButton.styleFrom(
                  primary: context.textColor,
                  splashFactory: NoSplash.splashFactory,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  s.cancel,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                style: OutlinedButton.styleFrom(
                  primary: context.textColor,
                  splashFactory: NoSplash.splashFactory,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () async {
                  if (ref.watch(groupState.notifier).isExisted(_newGroup)) {
                    setState(() => _error = 1);
                  } else {
                    ref
                        .watch(groupState.notifier)
                        .addGroup(PodcastGroup(_newGroup));
                    Navigator.of(context).pop();
                  }
                },
                child: Text(s.confirm,
                    style: TextStyle(color: context.accentColor)),
              )
            ],
            title: SizedBox(child: Text(s.newGroup)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    hintText: s.newGroup,
                    hintStyle: TextStyle(fontSize: 18),
                    filled: true,
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: context.accentColor, width: 2.0),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: context.accentColor, width: 2.0),
                    ),
                  ),
                  cursorRadius: Radius.circular(2),
                  autofocus: true,
                  maxLines: 1,
                  controller: _controller,
                  onChanged: (value) {
                    _newGroup = value;
                  },
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: (_error == 1)
                      ? Text(
                          s.groupExisted,
                          style: TextStyle(color: Colors.red[400]),
                        )
                      : Center(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
