import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../utils/extension_helper.dart';

class EpisodeBrief extends Equatable {
  final String? title;
  final String description;
  final int? pubDate;
  final int? enclosureLength;
  final String enclosureUrl;
  final String? feedTitle;
  final String? primaryColor;
  final int? liked;
  final String? downloaded;
  final int? duration;
  final int? explicit;
  final String? imagePath;
  final String? mediaId;
  final int? isNew;
  final int? skipSecondsStart;
  final int? skipSecondsEnd;
  final int? downloadDate;
  EpisodeBrief(
      this.title,
      this.enclosureUrl,
      this.enclosureLength,
      this.pubDate,
      this.feedTitle,
      this.primaryColor,
      this.duration,
      this.explicit,
      this.imagePath,
      this.isNew,
      {this.mediaId,
      this.liked,
      this.downloaded,
      this.skipSecondsStart,
      this.skipSecondsEnd,
      this.description = '',
      this.downloadDate = 0});

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

  EpisodeBrief copyWith({
    String? mediaId,
  }) =>
      EpisodeBrief(title, enclosureUrl, enclosureLength, pubDate, feedTitle,
          primaryColor, duration, explicit, imagePath, isNew,
          mediaId: mediaId ?? this.mediaId,
          downloaded: downloaded,
          skipSecondsStart: skipSecondsStart,
          skipSecondsEnd: skipSecondsEnd,
          description: description,
          downloadDate: downloadDate);

  @override
  List<Object?> get props => [enclosureUrl, title];

  @override
  String toString() {
    return '$title $enclosureUrl';
  }
}
