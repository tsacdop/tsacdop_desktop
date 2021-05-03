import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_audio_desktop/flutter_audio_desktop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/episodebrief.dart';
import '../storage/key_value_storage.dart';
import '../storage/sqflite_db.dart';

import 'downloader.dart';

final audioState = ChangeNotifierProvider((ref) => AudioState(ref.read));

class AudioState extends ChangeNotifier {
  AudioState(this.read);

  @override
  void addListener(listener) {
    super.addListener(listener);
    _initQueue();
  }

  @override
  void dispose() {
    _audioPlayer.release();
    super.dispose();
  }

  final _dbHelper = DBHelper();
  final _playlistStorage = KeyValueStorage(playlistKey);
  final Reader read;

  var _audioPlayer;
  var _position = Duration.zero;
  Duration get position => _position;

  var _duration = Duration.zero;
  Duration get duration => _duration;

  var _playerRunning = false;
  bool get playerRunning => _playerRunning;

  EpisodeBrief _playingEpisode;
  EpisodeBrief get playingEpisode => _playingEpisode;

  bool get playing => _audioPlayer?.isPlaying;

  List<String> _queue;

  List<String> get queue => _queue;

  bool get _haveNext => _queue.isNotEmpty;

  double get volume => _audioPlayer?.volume ?? 1;

  var _noSlide = true;

  void loadEpisode(String url) async {
    final downloaded = await _dbHelper.isDownloaded(url);
    if (!downloaded) {
      final episode = await _dbHelper.getRssItemWithUrl(url);
      await read(downloadProvider.notifier).download(episode);
    }
    final episodeNew = await _dbHelper.getRssItemWithUrl(url);
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _playerRunning = true;
      notifyListeners();
    }
    await _audioPlayer?.stop();
    await _audioPlayer.load(episodeNew.mediaId);
    var currentDuration = await _audioPlayer.getDuration();
    if (currentDuration is Duration) {
      _duration = currentDuration;
    }
    _playingEpisode = episodeNew;
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
      if (_duration == _position && _position != Duration.zero) {
        timer.cancel();
        playNext();
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

  Future<void> slideSeek(double value, {bool end = false}) async {
    _noSlide = false;
    var seekValue = _duration * value;
    _position = seekValue;
    notifyListeners();
    if (end) {
      await _audioPlayer.setPosition(seekValue);
      _noSlide = true;
    }
  }

  void setVolume(double value) {
    _audioPlayer.setVolume(value);
  }

  void playNext() {
    if (_haveNext) {
      _queue.remove(_playingEpisode.enclosureUrl);
      loadEpisode(_queue.first);
      _saveQueue();
    } else {
      stop();
    }
  }

  Future<void> _seekRelative(Duration duration) async {
    var seekPosition = _position + duration;
    print(seekPosition.inSeconds);
    if (seekPosition < Duration.zero) seekPosition = Duration.zero;
    await _audioPlayer.setPosition(seekPosition);
  }

  Future<void> fastForward(Duration duration) async {
    await _seekRelative(duration);
  }

  Future<void> rewind(Duration duration) async {
    await _seekRelative(-duration);
  }

  void stop() {
    _audioPlayer?.stop();
    _playerRunning = false;
    _audioPlayer = null;
    notifyListeners();
  }

  Future<void> _initQueue() async {
    _queue = await _playlistStorage.getStringList();
    notifyListeners();
  }

  Future<void> _saveQueue() async {
    notifyListeners();
    await _playlistStorage.saveStringList(_queue);
  }

  void addToPlaylist(String url) async {
    if (!_queue.contains(url)) {
      _queue = [..._queue, url];
      final downloaded = await _dbHelper.isDownloaded(url);
      if (!downloaded) {
        final episode = await _dbHelper.getRssItemWithUrl(url);
        await read(downloadProvider).download(episode);
      }
      _saveQueue();
    }
  }

  void removeFromPlaylist(String url) {
    _queue = _queue.where((e) => e != url).toList();
    _saveQueue();
  }
}

class PlaybackState {
  final Duration position;
  final Duration audioDuration;
  final EpisodeBrief episode;

  PlaybackState(this.episode, {this.position, this.audioDuration});
}
