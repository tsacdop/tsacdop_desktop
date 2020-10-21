import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tsacdop_desktop/providers/audio_state.dart';
import 'package:tsacdop_desktop/widgets/custom_slider.dart';
import '../utils/extension_helper.dart';
import 'podcasts_page.dart';

class PlayerWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final audio = watch(audioState);
    if (audio.playerRunning)
      return Container(
        height: 100,
        width: double.infinity,
        color: context.primaryColor,
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: audio.playingEpisode == null
                    ? Center()
                    : Image.file(File("${audio.playingEpisode.imagePath}")),
              ),
              InkWell(
                onTap: () =>
                    context.read(openEpisode).state = audio.playingEpisode,
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(audio?.playingEpisode?.title ?? '',
                          maxLines: 2,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            splashRadius: 20,
                            icon: Icon(LineIcons.fast_backward_solid),
                            onPressed: () =>
                                audio.rewind(Duration(seconds: 15)),
                          ),
                          SizedBox(width: 50),
                          audio.playing
                              ? IconButton(
                                  splashRadius: 20,
                                  icon: Icon(LineIcons.pause_circle_solid,
                                      size: 25),
                                  onPressed: audio.pauseAduio,
                                )
                              : IconButton(
                                  splashRadius: 20,
                                  icon: Icon(LineIcons.play_circle_solid,
                                      size: 25),
                                  onPressed: audio.play),
                          SizedBox(width: 50),
                          IconButton(
                            splashRadius: 20,
                            icon: Icon(LineIcons.fast_forward_solid),
                            onPressed: () =>
                                audio.fastForward(Duration(seconds: 15)),
                          ),
                          IconButton(
                            splashRadius: 20,
                            icon: Icon(LineIcons.window_close_solid),
                            onPressed: audio.stop,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 10, left: 30, right: 30),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: context.accentColor.withAlpha(70),
                          inactiveTrackColor: context.primaryColorDark,
                          trackHeight: 4.0,
                          trackShape: MyRectangularTrackShape(),
                          thumbColor: context.accentColor,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 6.0,
                            disabledThumbRadius: 6.0,
                          ),
                          overlayColor: context.accentColor.withAlpha(32),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 4.0),
                        ),
                        child: Slider(
                          value: audio.duration == Duration.zero
                              ? 0
                              : audio.position.inMilliseconds /
                                  audio.duration.inMilliseconds,
                          onChanged: audio.slideSeek,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(audio.position.inSeconds.toTime),
                          Text(audio.duration.inSeconds.toTime)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    return Center();
  }
}
