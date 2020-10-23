import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/episodebrief.dart';
import '../models/podcastlocal.dart';
import '../widgets/custom_dropdown.dart';
import '../providers/group_state.dart';
import '../utils/extension_helper.dart';
import 'episode_detail.dart';
import 'home_tabs.dart';
import 'podcast_detail.dart';

final openPodcast = StateProvider<PodcastLocal>((ref) => null);
final openEpisode = StateProvider<EpisodeBrief>((ref) => null);

class PodcastsPage extends StatelessWidget {
  PodcastsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: _PodcastGroup()),
          Expanded(
              flex: 2,
              child: Consumer(builder: (context, watch, _) {
                final podcast = watch(openPodcast).state;
                final episode = watch(openEpisode).state;
                if (episode != null)
                  return EpisodeDetail(episode);
                else if (podcast != null) return PodcastDetail(podcast);
                return HomeTabs();
              })),
        ],
      ),
    );
  }
}

class _PodcastGroup extends StatefulWidget {
  const _PodcastGroup({Key key}) : super(key: key);

  @override
  __PodcastGroupState createState() => __PodcastGroupState();
}

class __PodcastGroupState extends State<_PodcastGroup> {
  int _groupIndex;
  @override
  void initState() {
    super.initState();
    _groupIndex = 0;
  }

  Widget _podcastListTile(BuildContext context, PodcastLocal podcast) =>
      ListTile(
          onTap: () {
            context.read(openEpisode).state = null;
            context.read(openPodcast).state = podcast;
          },
          contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 10),
          leading: CircleAvatar(
              backgroundColor: podcast.backgroudColor(context).withOpacity(0.5),
              backgroundImage: podcast.avatarImage),
          title: Text(podcast.title,
              maxLines: 1, style: context.textTheme.bodyText1),
          subtitle: Text(
            podcast.author,
            maxLines: 1,
          ),
          trailing: Consumer(builder: (context, watch, _) {
            return watch(openPodcast).state == podcast
                ? Container(width: 5, color: context.accentColor)
                : SizedBox(
                    width: 2,
                  );
          }));

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, child) {
      final groupList = watch(groupState.state);
      if (groupList.isEmpty) {
        return Center();
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
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
                      value: groupList.indexOf(group), child: Text(group.name))
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
                    barrierColor: Colors.black54,
                    transitionDuration: const Duration(milliseconds: 200),
                    pageBuilder: (context, animaiton, secondaryAnimation) =>
                        AddGroup());
              },
            ),
          ),
          FutureBuilder<List<PodcastLocal>>(
            future: groupList[_groupIndex].getPodcasts(),
            initialData: [],
            builder: (context, snapshot) {
              if (snapshot.data.isEmpty) return Center();
              return Expanded(
                  child: ListView(
                shrinkWrap: true,
                children: [
                  for (var podcast in snapshot.data)
                    _podcastListTile(context, podcast)
                ],
              ));
            },
          ),
        ],
      );
    });
  }
}

class AddGroup extends StatefulWidget {
  @override
  _AddGroupState createState() => _AddGroupState();
}

class _AddGroupState extends State<AddGroup> {
  TextEditingController _controller;
  String _newGroup;
  int _error;

  @override
  void initState() {
    super.initState();
    _error = 0;
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      titlePadding: EdgeInsets.all(20),
      actionsPadding: EdgeInsets.all(4),
      actions: <Widget>[
        TextButton(
          style: OutlinedButton.styleFrom(
            primary: context.textColor,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          onPressed: () async {
            if (context.read(groupState).isExisted(_newGroup)) {
              setState(() => _error = 1);
            } else {
              context.read(groupState).addGroup(PodcastGroup(_newGroup));
              Navigator.of(context).pop();
            }
          },
          child: Text(s.confirm, style: TextStyle(color: context.accentColor)),
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
                borderSide: BorderSide(color: context.accentColor, width: 2.0),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.accentColor, width: 2.0),
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
    );
  }
}
