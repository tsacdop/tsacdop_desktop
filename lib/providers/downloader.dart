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
  DownloadTask(
    this.episode, {
    String taskId,
    this.filename,
    this.savedDir,
    this.timeCreated,
    this.progress = 0,
    this.status = DownloadTaskStatus.undefined,
  }) : taskId = taskId ?? Uuid().v4();

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

final downloadProvider = StateNotifierProvider((ref) => Downloader());

class Downloader extends StateNotifier<List<DownloadTask>> {
  Downloader([List<DownloadTask> initialTodos]) : super([]);

  final _dio = Dio(BaseOptions(
    connectTimeout: 30000,
  ));

  var _cancelToken;
  var _dbHelper = DBHelper();

  int indexOf(EpisodeBrief episode) {
    for (var task in state) {
      if (task.episode == episode) return state.indexOf(task);
    }
    return -1;
  }

  Future<void> download(EpisodeBrief episode) async {
    final dir = await getDownloadsDirectory();
    var localPath = path.join(dir.path, 'Tsacdop');
    final saveDir = Directory(localPath);
    var hasExisted = await saveDir.exists();
    if (!hasExisted) {
      saveDir.create();
    }
    var savePath = path.join(localPath, episode.feedTitle.replaceAll(' ', ''));
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
    var fileName =
        '${episode.title}$datePlus.${episode.enclosureUrl.split('/').last.split('.').last}';
    if (fileName.length > 100) {
      fileName = fileName.substring(fileName.length - 100);
    }
    var filePath = path.join(savePath, Uri.encodeComponent(fileName));
    var downloadTask = DownloadTask(episode,
        filename: fileName,
        savedDir: savePath,
        timeCreated: now.millisecondsSinceEpoch,
        status: DownloadTaskStatus.enqueued);

    state.add(downloadTask);
    var index = state.indexOf(downloadTask);

    var response = await _dio.download(episode.enclosureUrl, filePath,
        cancelToken: _cancelToken, onReceiveProgress: (count, total) {
      if (total > 0 && count > 0) {
        var progress = (count * 100) ~/ total;
        state[index] = downloadTask.copyWith(
            progress: progress, status: DownloadTaskStatus.running);
      }
    }, deleteOnError: true);
    if (response.statusCode == 200) {
      state[index] = downloadTask.copyWith(
          progress: 100, status: DownloadTaskStatus.complete);
      var fileStat = await File(filePath).stat();
      _dbHelper.saveMediaId(
          episode.enclosureUrl, filePath, downloadTask.taskId, fileStat.size);
    } else {
      state[index] = downloadTask.copyWith(status: DownloadTaskStatus.failed);
    }
  }

  Future<void> deleteDownload(EpisodeBrief episode) async {
    final episodeNew = await _dbHelper.getRssItemWithUrl(episode.enclosureUrl);
    var file = File(episodeNew.mediaId);
    if (file.existsSync()) {
      await file.delete();
    }
    await _dbHelper.delDownloaded(episode.enclosureUrl);
    state.removeWhere((task) => task.episode == episode);
  }
}
