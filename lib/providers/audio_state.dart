import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_audio_desktop/flutter_audio_desktop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsacdop_desktop/models/episodebrief.dart';
import 'package:tsacdop_desktop/storage/sqflite_db.dart';

import 'downloader.dart';

final audioState = ChangeNotifierProvider((ref) => AudioState(ref.read));

class AudioState extends ChangeNotifier {
  AudioState(this.read);

  @override
  void addListener(listener) {
    super.addListener(listener);
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.release();
    super.dispose();
  }

  final _dbHelper = DBHelper();
  final Reader read;

  var _audioPlayer;
  var _position = Duration.zero;
  Duration get position => _position;

  var _duration = Duration.zero;
  Duration get duration => _duration;

  var _playerRunning = false;
  bool get playerRunning => _playerRunning;

  var _playingEpisode;
  EpisodeBrief get playingEpisode => _playingEpisode;

  bool get playing => _audioPlayer?.isPlaying;

  var _noSlide = true;

  Future<void> loadEpisode(EpisodeBrief episode) async {
    final downloaded = await _dbHelper.isDownloaded(episode.enclosureUrl);
    if (!downloaded) {
      await read(downloadProvider).download(episode);
    }
    final episodeNew = await _dbHelper.getRssItemWithUrl(episode.enclosureUrl);
    if (!_playerRunning) {
      _audioPlayer = AudioPlayer();
      _playerRunning = true;
      notifyListeners();
    }
    await _audioPlayer?.stop();
    print(episode.mediaId);
    await _audioPlayer.load(episodeNew.mediaId);
    _duration = await _audioPlayer.getDuration();
    _playingEpisode = episode;
    notifyListeners();
    await _audioPlayer.play();
    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (_noSlide) {
        var currentPosition = await _audioPlayer.getPosition();
        if (currentPosition is Duration) {
          _position = currentPosition;
        }
        notifyListeners();
      }
      if (_audioPlayer == null) {
        timer.cancel();
      }
    });
  }

  void pauseAduio() async {
    await _audioPlayer.pause();
  }

  void play() {
    _audioPlayer.play();
  }

  void seekTo(Duration duration) {
    _audioPlayer.setPosition(duration);
  }

  void slideSeek(double value) {
    _noSlide = false;
    notifyListeners();
    var seekValue = (_duration.inMilliseconds * value).toInt();
    seekTo(Duration(milliseconds: seekValue));
    _noSlide = true;
    notifyListeners();
  }

  void _seekRelative(Duration duration) {
    var seekPosition = _position + duration;
    if (seekPosition < Duration.zero) seekPosition = Duration.zero;
    seekTo(seekPosition);
  }

  void fastForward(Duration duration) {
    _seekRelative(duration);
  }

  void rewind(Duration duration) {
    _seekRelative(-duration);
  }
}
