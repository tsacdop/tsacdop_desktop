import 'dart:io';
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:tsacdop_desktop/storage/sqflite_db.dart';
import 'package:uuid/uuid.dart';
import '../models/episodebrief.dart';

enum DownloadTaskStatus {
  undefined,
  enqueued,
  running,
  complete,
  failed,
  canceled,
  paused
}

class DownloadTask extends Equatable {
  final EpisodeBrief episode;
  final String taskId;
  final String filename;
  final String savedDir;
  final int timeCreated;
  final int progress;
  final DownloadTaskStatus status;
  final CancelToken cancelToken;
  DownloadTask(this.episode,
      {String taskId,
      this.filename,
      this.savedDir,
      this.timeCreated,
      this.progress = 0,
      this.status = DownloadTaskStatus.undefined,
      this.cancelToken})
      : taskId = taskId ?? Uuid().v4();

  DownloadTask copyWith({int progress, DownloadTaskStatus status}) {
    return DownloadTask(episode,
        filename: filename,
        savedDir: savedDir,
        timeCreated: timeCreated,
        taskId: taskId,
        progress: progress,
        status: status);
  }

  @override
  List<Object> get props => [taskId, episode.enclosureUrl];
}

final downloadNotification = StateProvider<String>((ref) => null);

final downloadProvider = StateNotifierProvider((ref) => Downloader(ref.read));

class Downloader extends StateNotifier<List<DownloadTask>> {
  Downloader(this.read) : super([]);

  final Reader read;

  final _dio = Dio(BaseOptions(
    connectTimeout: 30000,
  ));

  final _pathInvilid = RegExp(r'\/|\\|\?|\*|\.');
  var _dbHelper = DBHelper();

  int indexOf(EpisodeBrief episode) {
    for (var task in state) {
      if (task.episode == episode) return state.indexOf(task);
    }
    return -1;
  }

  void _updateTask(DownloadTask downloadTask) {
    state = [
      for (var task in state)
        if (task.taskId == downloadTask.taskId) downloadTask else task
    ];
  }

  Future<void> download(EpisodeBrief episode) async {
    final dir = await getDownloadsDirectory();
    var localPath = path.join(dir.path, 'Tsacdop');
    final saveDir = Directory(localPath);
    var hasExisted = await saveDir.exists();
    if (!hasExisted) {
      saveDir.create();
    }
    var feedTile =
        episode.feedTitle.replaceAll(' ', '_').replaceAll(_pathInvilid, '');
    var savePath = path.join(localPath, Uri.encodeComponent(feedTile));
    final podcastDir = Directory(savePath);
    var dirExisted = await podcastDir.exists();
    if (!dirExisted) {
      podcastDir.create();
    }
    var now = DateTime.now();
    var datePlus = now.year.toString() +
        now.month.toString() +
        now.day.toString() +
        now.second.toString();
    var title = episode.title.replaceAll(' ', '_').replaceAll(_pathInvilid, '');
    var fileName =
        '$title$datePlus.${episode.enclosureUrl.split('/').last.split('.').last}';
    fileName = Uri.encodeComponent(fileName);
    if (fileName.length > 50) {
      fileName = fileName.substring(fileName.length - 50);
    }
    var filePath = path.join(savePath, fileName);
    var cancelToken;
    var downloadTask = DownloadTask(episode,
        filename: fileName,
        savedDir: savePath,
        timeCreated: now.millisecondsSinceEpoch,
        status: DownloadTaskStatus.enqueued,
        cancelToken: cancelToken);

    state = [...state, downloadTask];
    var response = await _dio.download(episode.enclosureUrl, filePath,
        cancelToken: cancelToken, onReceiveProgress: (count, total) {
      if (total > 0 && count > 0) {
        var progress = (count * 100) ~/ total;
        _updateTask(downloadTask.copyWith(
            progress: progress, status: DownloadTaskStatus.running));
        if (read(downloadNotification).state == null ||
            read(downloadNotification).state.contains(episode.title))
          read(downloadNotification).state =
              'Downloading ${episode.title} $progress%';
      }
    }, deleteOnError: true);
    if (response.statusCode == 200) {
      _updateTask(downloadTask.copyWith(
          progress: 100, status: DownloadTaskStatus.complete));
      read(downloadNotification).state = null;
      var fileStat = await File(filePath).stat();
      _dbHelper.saveMediaId(
          episode.enclosureUrl, filePath, downloadTask.taskId, fileStat.size);
    } else {
      _updateTask(downloadTask.copyWith(status: DownloadTaskStatus.failed));
      read(downloadNotification).state = null;
    }
  }

  void cancelDownload(DownloadTask task) {
    var cancelToken = task.cancelToken;
    cancelToken?.cancel();
    state = state.where((t) => t != task).toList();
  }

  Future<void> deleteDownload(EpisodeBrief episode) async {
    final episodeNew = await _dbHelper.getRssItemWithUrl(episode.enclosureUrl);
    var file = File(episodeNew.mediaId);
    if (file.existsSync()) {
      print(file.path);
      await file.delete();
    }
    await _dbHelper.delDownloaded(episode.enclosureUrl);
    state = state.where((task) => task.episode != episode).toList();
  }
}
