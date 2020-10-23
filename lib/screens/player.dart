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
                    SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  splashRadius: 20,
                                  icon: Icon(LineIcons.fast_backward_solid),
                                  onPressed: () async =>
                                      await audio.rewind(Duration(seconds: 15)),
                                ),
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
                                IconButton(
                                  splashRadius: 20,
                                  icon: Icon(LineIcons.fast_forward_solid),
                                  onPressed: () async => await audio
                                      .fastForward(Duration(seconds: 15)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  splashRadius: 20,
                                  onPressed: () => audio.setVolume(0),
                                  icon: Icon(
                                    LineIcons.volume_down_solid,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor:
                                          context.primaryColorDark,
                                      inactiveTrackColor:
                                          context.primaryColorDark,
                                      activeTickMarkColor:
                                          context.primaryColorDark,
                                      trackHeight: 2.0,
                                      thumbColor: context.primaryColorDark,
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 6.0,
                                        disabledThumbRadius: 6.0,
                                      ),
                                      overlayColor: context.primaryColorDark,
                                      overlayShape: RoundSliderOverlayShape(
                                          overlayRadius: 4.0),
                                    ),
                                    child: Slider(
                                        divisions: 10,
                                        label: audio.volume.toStringAsFixed(2),
                                        value: audio.volume,
                                        onChanged: (value) {
                                          audio.setVolume(value);
                                        }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  splashRadius: 20,
                                  icon: Icon(LineIcons.step_forward_solid),
                                  onPressed: audio.playNext,
                                ),
                                IconButton(
                                  splashRadius: 20,
                                  icon: Icon(LineIcons.window_close_solid),
                                  onPressed: audio.stop,
                                ),
                              ],
                            ),
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
                          onChangeEnd: (value) {
                            audio.slideSeek(value, end: true);
                          },
                          onChanged: (value) => audio.slideSeek(value),
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
