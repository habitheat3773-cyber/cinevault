import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/movie_model.dart';

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  // Public TMDB API key - users can replace with their own
  static const String _apiKey = 'YOUR_TMDB_API_KEY';
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    queryParameters: {'api_key': _apiKey, 'language': 'en-US'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ─── TRENDING ───────────────────────────────────────────
  Future<List<Movie>> getTrending({String mediaType = 'all', String timeWindow = 'week'}) async {
    final res = await _dio.get('/trending/$mediaType/$timeWindow');
    return _parseResults(res.data['results']);
  }

  // ─── POPULAR ────────────────────────────────────────────
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    final res = await _dio.get('/movie/popular', queryParameters: {'page': page});
    return _parseResults(res.data['results']);
  }

  Future<List<Movie>> getPopularShows({int page = 1}) async {
    final res = await _dio.get('/tv/popular', queryParameters: {'page': page});
    return _parseResults(res.data['results'], isMovie: false);
  }

  // ─── TOP RATED ──────────────────────────────────────────
  Future<List<Movie>> getTopRated({bool isMovie = true}) async {
    final endpoint = isMovie ? '/movie/top_rated' : '/tv/top_rated';
    final res = await _dio.get(endpoint);
    return _parseResults(res.data['results'], isMovie: isMovie);
  }

  // ─── UPCOMING ───────────────────────────────────────────
  Future<List<Movie>> getUpcoming() async {
    final res = await _dio.get('/movie/upcoming');
    return _parseResults(res.data['results']);
  }

  // ─── NOW PLAYING ────────────────────────────────────────
  Future<List<Movie>> getNowPlaying() async {
    final res = await _dio.get('/movie/now_playing');
    return _parseResults(res.data['results']);
  }

  // ─── BY GENRE ───────────────────────────────────────────
  Future<List<Movie>> getByGenre(int genreId, {bool isMovie = true, int page = 1}) async {
    final endpoint = isMovie ? '/discover/movie' : '/discover/tv';
    final res = await _dio.get(endpoint, queryParameters: {
      'with_genres': genreId,
      'sort_by': 'popularity.desc',
      'page': page,
    });
    return _parseResults(res.data['results'], isMovie: isMovie);
  }

  // ─── SEARCH ─────────────────────────────────────────────
  Future<List<Movie>> search(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final res = await _dio.get('/search/multi', queryParameters: {
      'query': query,
      'page': page,
      'include_adult': false,
    });
    final results = (res.data['results'] as List).where((item) =>
      item['media_type'] == 'movie' || item['media_type'] == 'tv'
    ).toList();
    return results.map((item) => Movie.fromTmdb(
      item, isMovie: item['media_type'] == 'movie'
    )).toList();
  }

  // ─── DETAIL ─────────────────────────────────────────────
  Future<Movie?> getMovieDetail(String id, {bool isMovie = true}) async {
    try {
      final endpoint = isMovie ? '/movie/$id' : '/tv/$id';
      final res = await _dio.get(endpoint, queryParameters: {
        'append_to_response': 'videos,credits,similar,external_ids',
      });
      final data = res.data;
      Movie movie = Movie.fromTmdb(data, isMovie: isMovie);
      
      // Extract trailer
      String? trailerKey;
      final videos = data['videos']?['results'] as List? ?? [];
      final trailer = videos.firstWhere(
        (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
        orElse: () => null,
      );
      if (trailer != null) trailerKey = trailer['key'];

      // Extract cast
      final castData = data['credits']?['cast'] as List? ?? [];
      final cast = castData.take(15).map((c) => CastMember(
        name: c['name'] ?? '',
        character: c['character'],
        profilePath: c['profile_path'],
      )).toList();

      return movie.copyWith(trailerKey: trailerKey, cast: cast);
    } catch (e) {
      return null;
    }
  }

  // ─── SIMILAR ────────────────────────────────────────────
  Future<List<Movie>> getSimilar(String id, {bool isMovie = true}) async {
    final endpoint = isMovie ? '/movie/$id/similar' : '/tv/$id/similar';
    final res = await _dio.get(endpoint);
    return _parseResults(res.data['results'], isMovie: isMovie);
  }

  // ─── OTT / PLATFORM CONTENT ─────────────────────────────
  Future<List<Movie>> getByOTT(String ottName, {int page = 1}) async {
    // Map OTT names to TMDB watch provider IDs
    final ottIds = {
      'Netflix': '8',
      'JioCinema': '220',
      'Hotstar': '122',
      'SonyLiv': '237',
      'Zee5': '232',
      'MXPlayer': '515',
      'Amazon': '119',
      'Apple': '2',
    };
    final providerId = ottIds[ottName];
    if (providerId == null) return getPopularMovies(page: page);
    
    final res = await _dio.get('/discover/movie', queryParameters: {
      'with_watch_providers': providerId,
      'watch_region': 'IN',
      'sort_by': 'popularity.desc',
      'page': page,
    });
    return _parseResults(res.data['results']);
  }

  // ─── GENRES LIST ────────────────────────────────────────
  Future<Map<int, String>> getGenres({bool isMovie = true}) async {
    final endpoint = isMovie ? '/genre/movie/list' : '/genre/tv/list';
    final res = await _dio.get(endpoint);
    final genres = <int, String>{};
    for (final g in res.data['genres']) {
      genres[g['id']] = g['name'];
    }
    return genres;
  }

  List<Movie> _parseResults(List? results, {bool isMovie = true}) {
    if (results == null) return [];
    return results
        .where((item) => item['poster_path'] != null)
        .map((item) {
          final mediaType = item['media_type'];
          final isMov = mediaType != null 
              ? mediaType == 'movie' 
              : isMovie;
          return Movie.fromTmdb(item, isMovie: isMov);
        })
        .toList();
  }
}

// Genre constants with IDs
class TmdbGenres {
  static const Map<String, int> movie = {
    'Action': 28, 'Adventure': 12, 'Animation': 16, 'Comedy': 35,
    'Crime': 80, 'Documentary': 99, 'Drama': 18, 'Family': 10751,
    'Fantasy': 14, 'History': 36, 'Horror': 27, 'Music': 10402,
    'Mystery': 9648, 'Romance': 10749, 'Science Fiction': 878,
    'Thriller': 53, 'War': 10752, 'Western': 37,
  };
  static const Map<String, int> tv = {
    'Action & Adventure': 10759, 'Animation': 16, 'Comedy': 35,
    'Crime': 80, 'Documentary': 99, 'Drama': 18, 'Family': 10751,
    'Kids': 10762, 'Mystery': 9648, 'News': 10763, 'Reality': 10764,
    'Sci-Fi & Fantasy': 10765, 'Soap': 10766, 'Talk': 10767,
    'War & Politics': 10768, 'Western': 37,
  };
}
