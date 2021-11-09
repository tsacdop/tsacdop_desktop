import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_notifications/desktop_notifications.dart';

import '../models/episodebrief.dart';
import '../storage/key_value_storage.dart';
import '../storage/sqflite_db.dart';

final audioState = ChangeNotifierProvider((ref) => AudioState(ref.read as T Function<T>(ProviderBase<T>)));

class AudioState extends ChangeNotifier {
  AudioState(this.read);

  @override
  void addListener(listener) {
    super.addListener(listener);
    _initQueue();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _generalStateStream?.cancel();
    _playbackStateStream?.cancel();
    _postionStateStream?.cancel();
    _notifyClinet?.close();
    super.dispose();
  }

  final _dbHelper = DBHelper();
  final _playlistStorage = KeyValueStorage(playlistKey);
  final _notifyClinet = NotificationsClient();
  final Reader read;

  Player? _audioPlayer;
  late Playlist _playlist;
  StreamSubscription<GeneralState>? _generalStateStream;
  StreamSubscription<PlaybackState>? _playbackStateStream;
  StreamSubscription<PositionState>? _postionStateStream;

  Duration? _position = Duration.zero;

  Duration? get position => _position;

  Duration? _duration = Duration.zero;
  Duration? get duration => _duration;

  var _playerRunning = false;
  bool get playerRunning => _playerRunning;

  EpisodeBrief? _playingEpisode;
  EpisodeBrief? get playingEpisode => _playingEpisode;

  bool _playing = false;
  bool get playing => _playing;

  bool _buffering = false;
  bool get buffering => _buffering;

  List<String>? _queue = [];

  List<String>? get queue => _queue;

  bool get _haveNext => _queue!.isNotEmpty;

  double? _volume;
  double get volume => _volume ?? 1;

  var _noSlide = true;

  void loadEpisode(String url) async {
    final episodeNew = await (_dbHelper.getRssItemWithUrl(url) as FutureOr<EpisodeBrief>);
    if (_audioPlayer == null) {
      _audioPlayer = Player(id: 69420);
      _playerRunning = true;
      notifyListeners();
    }
    _audioPlayer?.stop();
    _playlist = Playlist(medias: [Media.network(episodeNew.enclosureUrl)]);
    _audioPlayer!.open(_playlist);
    _generalStateStream = _audioPlayer!.generalStream.listen((event) {
      if (event is GeneralState) {
        _volume = event.volume;
        notifyListeners();
      }
    });
    _playbackStateStream = _audioPlayer!.playbackStream.listen((event) {
      if (event is PlaybackState) {
        if (event.isCompleted) {
          stop();
        }
        print(event.toString());
        _playing = event.isPlaying;
        _buffering = !event.isSeekable;
        notifyListeners();
      }
    });
    _postionStateStream = _audioPlayer!.positionStream.listen((event) {
      if (event is PositionState) {
        _duration = event.duration;
        if (_noSlide) _position = event.position;
        notifyListeners();
      }
    });
    _playingEpisode = episodeNew;
    _notifyEpisode(_playingEpisode);
    notifyListeners();
    _audioPlayer!.play();
  }

  void loadPlaylist() {
    final url = _queue!.first;
    loadEpisode(url);
  }

  void pauseAduio() async {
    _audioPlayer!.pause();
  }

  void play() {
    _audioPlayer!.play();
  }

  Future<void> slideSeek(double value, {bool end = false}) async {
    _noSlide = false;
    var seekValue = _duration! * value;
    _position = seekValue;
    notifyListeners();
    if (end) {
      _audioPlayer!.seek(seekValue);
      _noSlide = true;
    }
  }

  void setVolume(double value) {
    _audioPlayer!.setVolume(value);
  }

  void playNext() {
    if (_haveNext) {
      _queue!.remove(_playingEpisode!.enclosureUrl);
      loadEpisode(_queue!.first);
      _saveQueue();
    } else {
      stop();
    }
  }

  Future<void> _seekRelative(Duration duration) async {
    var seekPosition = _position! + duration;
    if (seekPosition < Duration.zero) seekPosition = Duration.zero;
    _audioPlayer!.seek(seekPosition);
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
    await _playlistStorage.saveStringList(_queue!);
  }

  void addToPlaylist(String url) async {
    if (!_queue!.contains(url)) {
      _queue = [..._queue!, url];
      _saveQueue();
    }
  }

  void removeFromPlaylist(String url) {
    _queue = _queue!.where((e) => e != url).toList();
    _saveQueue();
  }

  void _notifyEpisode(EpisodeBrief? episode) {
    if(Platform.isLinux) {
      _notifyClinet.notify(episode!.title!, appName: 'Tsacdop', appIcon: 'media-playback-start');
    }
  }
}

class CurrentPlaybackState {
  final Duration? position;
  final Duration? audioDuration;
  final EpisodeBrief episode;

  CurrentPlaybackState(this.episode, {this.position, this.audioDuration});
}
