import 'dart:async';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart';
import '../models/movie_model.dart';

// ─── BASE PROVIDER ──────────────────────────────────────────────────────────
abstract class BaseProvider {
  String get name;
  String get baseUrl;
  bool get isEnabled;
  bool get supportsMovies;
  bool get supportsShows;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
    },
  ));

  Dio get dio => _dio;

  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  });

  Future<bool> checkHealth() async {
    try {
      final res = await _dio.get(baseUrl);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String buildSearchUrl(String title);

  // Helper: extract m3u8/mp4 links from HTML
  List<String> extractVideoLinks(String html) {
    final links = <String>[];
    final patterns = [
      RegExp(r'https?://[^\s"\'<>]+\.m3u8[^\s"\'<>]*'),
      RegExp(r'https?://[^\s"\'<>]+\.mp4[^\s"\'<>]*'),
      RegExp(r'file:\s*["\']?(https?://[^\s"\'<>]+)["\']?'),
      RegExp(r'source\s+src=["\']?(https?://[^\s"\'<>]+)["\']?'),
    ];
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(html)) {
        final url = match.group(1) ?? match.group(0) ?? '';
        if (url.isNotEmpty) links.add(url);
      }
    }
    return links.toSet().toList();
  }

  String detectQuality(String url) {
    if (url.contains('4k') || url.contains('2160')) return '4K';
    if (url.contains('1080')) return '1080p';
    if (url.contains('720')) return '720p';
    if (url.contains('480')) return '480p';
    return '720p';
  }
}

// ─── PROVIDER REGISTRY ──────────────────────────────────────────────────────
class ProviderRegistry {
  static final List<BaseProvider> _all = [
    FlixHQProvider(),
    VidsrcProvider(),
    EmbedsuProvider(),
    MoviesApiProvider(),
    KatMoviesProvider(),
    HdHub4uProvider(),
    // Add more providers here
  ];

  static List<BaseProvider> get enabled =>
      _all.where((p) => p.isEnabled).toList();

  static List<BaseProvider> get all => _all;

  // Fetch streams from ALL providers in parallel
  static Future<List<StreamSource>> fetchAllStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    final results = await Future.wait(
      enabled.map((p) => p
          .getStreams(title, year,
              imdbId: imdbId,
              isMovie: isMovie,
              season: season,
              episode: episode)
          .timeout(const Duration(seconds: 15), onTimeout: () => [])
          .catchError((_) => <StreamSource>[])),
    );
    
    final allSources = results.expand((list) => list).toList();
    // Sort by quality: 4K > 1080p > 720p > 480p
    allSources.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    return allSources;
  }
}

// ─── VIDSRC PROVIDER (Reliable iframe embed) ────────────────────────────────
class VidsrcProvider extends BaseProvider {
  @override
  String get name => 'VidSrc';
  @override
  String get baseUrl => 'https://vidsrc.to';
  @override
  bool get isEnabled => true;
  @override
  bool get supportsMovies => true;
  @override
  bool get supportsShows => true;

  @override
  String buildSearchUrl(String title) => baseUrl;

  @override
  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    try {
      if (imdbId == null) return [];
      
      String embedUrl;
      if (isMovie) {
        embedUrl = '$baseUrl/embed/movie/$imdbId';
      } else {
        embedUrl = '$baseUrl/embed/tv/$imdbId/${season ?? 1}-${episode ?? 1}';
      }
      
      return [
        StreamSource(
          providerName: name,
          url: embedUrl,
          quality: '1080p',
          isWorking: true,
          lastChecked: DateTime.now(),
        ),
      ];
    } catch (_) {
      return [];
    }
  }
}

// ─── EMBEDSU PROVIDER ───────────────────────────────────────────────────────
class EmbedsuProvider extends BaseProvider {
  @override
  String get name => 'Embed.su';
  @override
  String get baseUrl => 'https://embed.su';
  @override
  bool get isEnabled => true;
  @override
  bool get supportsMovies => true;
  @override
  bool get supportsShows => true;

  @override
  String buildSearchUrl(String title) => baseUrl;

  @override
  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    try {
      if (imdbId == null) return [];
      String embedUrl;
      if (isMovie) {
        embedUrl = '$baseUrl/embed/movie/$imdbId';
      } else {
        embedUrl = '$baseUrl/embed/tv/$imdbId/${season ?? 1}/${episode ?? 1}';
      }
      return [
        StreamSource(
          providerName: name,
          url: embedUrl,
          quality: '720p',
          isWorking: true,
          lastChecked: DateTime.now(),
        ),
      ];
    } catch (_) {
      return [];
    }
  }
}

// ─── FLIXHQ PROVIDER ────────────────────────────────────────────────────────
class FlixHQProvider extends BaseProvider {
  @override
  String get name => 'FlixHQ';
  @override
  String get baseUrl => 'https://flixhq.to';
  @override
  bool get isEnabled => true;
  @override
  bool get supportsMovies => true;
  @override
  bool get supportsShows => true;

  @override
  String buildSearchUrl(String title) =>
      '$baseUrl/search/${Uri.encodeComponent(title)}';

  @override
  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    try {
      // Search for the movie
      final searchUrl = buildSearchUrl(title);
      final res = await dio.get(searchUrl);
      final doc = htmlParser.parse(res.data.toString());
      
      // Find matching result
      final items = doc.querySelectorAll('.film-poster');
      if (items.isEmpty) return [];
      
      final firstItem = items.first;
      final href = firstItem.querySelector('a')?.attributes['href'] ?? '';
      if (href.isEmpty) return [];
      
      final detailUrl = '$baseUrl$href';
      final detailRes = await dio.get(detailUrl);
      final detailDoc = htmlParser.parse(detailRes.data.toString());
      
      // Extract embed links
      final links = extractVideoLinks(detailRes.data.toString());
      
      return links.take(3).map((url) => StreamSource(
        providerName: name,
        url: url,
        quality: detectQuality(url),
        isWorking: true,
        lastChecked: DateTime.now(),
      )).toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── MOVIES API PROVIDER (consumet-style) ───────────────────────────────────
class MoviesApiProvider extends BaseProvider {
  @override
  String get name => 'MoviesAPI';
  @override
  String get baseUrl => 'https://moviesapi.club';
  @override
  bool get isEnabled => true;
  @override
  bool get supportsMovies => true;
  @override
  bool get supportsShows => true;

  @override
  String buildSearchUrl(String title) => baseUrl;

  @override
  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    try {
      if (imdbId == null) return [];
      String embedUrl;
      if (isMovie) {
        embedUrl = '$baseUrl/movie/$imdbId';
      } else {
        embedUrl = '$baseUrl/tv/$imdbId-${season ?? 1}-${episode ?? 1}';
      }
      return [
        StreamSource(
          providerName: name,
          url: embedUrl,
          quality: '1080p',
          isWorking: true,
          lastChecked: DateTime.now(),
        ),
      ];
    } catch (_) {
      return [];
    }
  }
}

// ─── KАТMOVIES PROVIDER ─────────────────────────────────────────────────────
class KatMoviesProvider extends BaseProvider {
  @override
  String get name => 'KatMovies';
  @override
  String get baseUrl => 'https://katmovies.pink';
  @override
  bool get isEnabled => true;
  @override
  bool get supportsMovies => true;
  @override
  bool get supportsShows => false;

  @override
  String buildSearchUrl(String title) =>
      '$baseUrl/?s=${Uri.encodeComponent(title)}';

  @override
  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    try {
      final searchUrl = buildSearchUrl('$title $year');
      final res = await dio.get(searchUrl);
      final links = extractVideoLinks(res.data.toString());
      return links.take(2).map((url) => StreamSource(
        providerName: name,
        url: url,
        quality: detectQuality(url),
        isWorking: true,
        lastChecked: DateTime.now(),
      )).toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── HDHUB4U PROVIDER ───────────────────────────────────────────────────────
class HdHub4uProvider extends BaseProvider {
  @override
  String get name => 'HdHub4u';
  @override
  String get baseUrl => 'https://hdhub4u.futbol';
  @override
  bool get isEnabled => true;
  @override
  bool get supportsMovies => true;
  @override
  bool get supportsShows => false;

  @override
  String buildSearchUrl(String title) =>
      '$baseUrl/?s=${Uri.encodeComponent(title)}';

  @override
  Future<List<StreamSource>> getStreams(
    String title,
    int year, {
    String? imdbId,
    bool isMovie = true,
    int? season,
    int? episode,
  }) async {
    try {
      final searchUrl = buildSearchUrl('$title $year');
      final res = await dio.get(searchUrl);
      final links = extractVideoLinks(res.data.toString());
      return links.take(3).map((url) => StreamSource(
        providerName: name,
        url: url,
        quality: detectQuality(url),
        isWorking: true,
        lastChecked: DateTime.now(),
      )).toList();
    } catch (_) {
      return [];
    }
  }
}
