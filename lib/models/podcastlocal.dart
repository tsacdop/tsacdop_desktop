import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../utils/extension_helper.dart';

class PodcastLocal extends Equatable {
  final String? title;
  final String? imageUrl;
  final String rssUrl;
  final String? author;
  final String? primaryColor;
  final String? id;
  final String? imagePath;
  final String? provider;
  final String? link;
  final String? description;
  final int upateCount;
  final int episodeCount;

  PodcastLocal(this.title, this.imageUrl, this.rssUrl, this.primaryColor,
      this.author, this.id, this.imagePath, this.provider, this.link,
      {this.description = '', int? upateCount, int? episodeCount})
      : episodeCount = episodeCount ?? 0,
        upateCount = upateCount ?? 0;

  ImageProvider get avatarImage {
    return (File(imagePath!).existsSync()
            ? FileImage(File(imagePath!))
            : const AssetImage('assets/avatar_backup.png'))
        as ImageProvider<Object>;
  }

  Color backgroudColor(BuildContext context) {
    return context.brightness == Brightness.light
        ? primaryColor!.colorizedark()
        : primaryColor!.colorizeLight();
  }

  @override
  List<Object?> get props => [id, rssUrl];
}
