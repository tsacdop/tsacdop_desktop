import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../models/service_api/index_episode.dart';
import '../models/service_api/index_podcast.dart';

import '../.env.dart';

const String version = '0.1.0';

class PodcastsIndexSearch {
  final _dio = Dio(BaseOptions(connectTimeout: 30000, receiveTimeout: 90000));
  final _baseUrl = 'https://api.podcastindex.org';
  Map<String, String> _initSearch() {
    final unixTime =
        (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    final apiKey = environment['podcastIndexApiKey'];
    final apiSecret = environment['podcastIndexApiSecret'];
    final firstChunk = utf8.encode(apiKey);
    final secondChunk = utf8.encode(apiSecret);
    final thirdChunk = utf8.encode(unixTime);
    var output = AccumulatorSink<Digest>();
    var input = sha1.startChunkedConversion(output);
    input.add(firstChunk);
    input.add(secondChunk);
    input.add(thirdChunk);
    input.close();
    var digest = output.events.single;

    var headers = <String, String>{
      "X-Auth-Date": unixTime,
      "X-Auth-Key": apiKey,
      "Authorization": digest.toString(),
      "User-Agent": "Tsacdop_Desktop/$version"
    };
    return headers;
  }

  Future<PodcastIndexSearchResult<dynamic>> searchPodcasts(
      {String searchText, int limit = 99}) async {
    final url = "$_baseUrl/api/1.0/search/byterm"
        "?q=${Uri.encodeComponent(searchText)}&max=$limit&fulltext=true";
    final headers = _initSearch();
    final response = await _dio.get(url, options: Options(headers: headers));
    Map searchResultMap = jsonDecode(response.toString());
    final searchResult = PodcastIndexSearchResult.fromJson(searchResultMap);
    return searchResult;
  }

  Future<IndexEpisodeResult<dynamic>> fetchEpisode({String rssUrl}) async {
    final url = "$_baseUrl/api/1.0/episodes/byfeedurl?url=$rssUrl";
    final headers = _initSearch();
    final response = await _dio.get(url, options: Options(headers: headers));
    Map searchResultMap = jsonDecode(response.toString());
    final searchResult = IndexEpisodeResult.fromJson(searchResultMap);
    return searchResult;
  }
}
