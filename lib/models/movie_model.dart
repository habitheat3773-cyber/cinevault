import 'package:hive/hive.dart';

part 'movie_model.g.dart';

@HiveType(typeId: 0)
class Movie extends HiveObject {
  @HiveField(0)
  final String id; // TMDB ID as string

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? posterPath;

  @HiveField(3)
  final String? backdropPath;

  @HiveField(4)
  final String? overview;

  @HiveField(5)
  final String? releaseDate;

  @HiveField(6)
  final double? voteAverage;

  @HiveField(7)
  final List<String> genres;

  @HiveField(8)
  final List<String> languages;

  @HiveField(9)
  final int? runtime; // in minutes

  @HiveField(10)
  final bool isMovie; // false = TV Show

  @HiveField(11)
  final String? imdbId;

  @HiveField(12)
  final int? year;

  @HiveField(13)
  final String? trailerKey; // YouTube key

  @HiveField(14)
  final String? status; // Released, Upcoming, etc.

  @HiveField(15)
  final List<String> availableProviders;

  @HiveField(16)
  final List<StreamSource> streamSources;

  @HiveField(17)
  final String? tagline;

  @HiveField(18)
  final int? voteCount;

  @HiveField(19)
  final List<CastMember> cast;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.genres = const [],
    this.languages = const [],
    this.runtime,
    this.isMovie = true,
    this.imdbId,
    this.year,
    this.trailerKey,
    this.status,
    this.availableProviders = const [],
    this.streamSources = const [],
    this.tagline,
    this.voteCount,
    this.cast = const [],
  });

  String get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : '';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
      : '';

  String get runtimeFormatted {
    if (runtime == null) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String get ratingFormatted =>
      voteAverage != null ? voteAverage!.toStringAsFixed(1) : 'N/A';

  bool get isUpcoming {
    if (releaseDate == null) return false;
    try {
      return DateTime.parse(releaseDate!).isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Duration? get timeUntilRelease {
    if (releaseDate == null) return null;
    try {
      final rel = DateTime.parse(releaseDate!);
      if (rel.isAfter(DateTime.now())) {
        return rel.difference(DateTime.now());
      }
    } catch (_) {}
    return null;
  }

  factory Movie.fromTmdb(Map<String, dynamic> json, {bool isMovie = true}) {
    final title = isMovie
        ? (json['title'] ?? json['name'] ?? 'Unknown')
        : (json['name'] ?? json['title'] ?? 'Unknown');
    final releaseDate = isMovie
        ? json['release_date']
        : json['first_air_date'];
    int? year;
    if (releaseDate != null && releaseDate.toString().length >= 4) {
      year = int.tryParse(releaseDate.toString().substring(0, 4));
    }
    return Movie(
      id: json['id'].toString(),
      title: title,
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'],
      releaseDate: releaseDate,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g['name'].toString())
              .toList() ??
          (json['genre_ids'] as List<dynamic>?)
              ?.map((g) => g.toString())
              .toList() ??
          [],
      languages: json['spoken_languages'] != null
          ? (json['spoken_languages'] as List)
              .map((l) => l['english_name']?.toString() ?? '')
              .toList()
          : [],
      runtime: json['runtime'],
      isMovie: isMovie,
      imdbId: json['imdb_id'],
      year: year,
      tagline: json['tagline'],
      status: json['status'],
    );
  }

  Movie copyWith({
    List<StreamSource>? streamSources,
    List<String>? availableProviders,
    String? trailerKey,
    List<CastMember>? cast,
  }) {
    return Movie(
      id: id,
      title: title,
      posterPath: posterPath,
      backdropPath: backdropPath,
      overview: overview,
      releaseDate: releaseDate,
      voteAverage: voteAverage,
      genres: genres,
      languages: languages,
      runtime: runtime,
      isMovie: isMovie,
      imdbId: imdbId,
      year: year,
      trailerKey: trailerKey ?? this.trailerKey,
      status: status,
      availableProviders: availableProviders ?? this.availableProviders,
      streamSources: streamSources ?? this.streamSources,
      tagline: tagline,
      voteCount: voteCount,
      cast: cast ?? this.cast,
    );
  }
}

@HiveType(typeId: 1)
class StreamSource {
  @HiveField(0)
  final String providerName;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String quality; // 4K, 1080p, 720p, 480p

  @HiveField(3)
  final String? subtitle;

  @HiveField(4)
  final bool isWorking;

  @HiveField(5)
  final DateTime? lastChecked;

  const StreamSource({
    required this.providerName,
    required this.url,
    required this.quality,
    this.subtitle,
    this.isWorking = true,
    this.lastChecked,
  });

  int get qualityScore {
    switch (quality) {
      case '4K':
        return 4;
      case '1080p':
        return 3;
      case '720p':
        return 2;
      case '480p':
        return 1;
      default:
        return 0;
    }
  }
}

@HiveType(typeId: 2)
class CastMember {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String? character;

  @HiveField(2)
  final String? profilePath;

  const CastMember({
    required this.name,
    this.character,
    this.profilePath,
  });

  String get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : '';
}

// Watch history entry
@HiveType(typeId: 3)
class WatchHistoryEntry extends HiveObject {
  @HiveField(0)
  final String movieId;

  @HiveField(1)
  final String movieTitle;

  @HiveField(2)
  final String? posterPath;

  @HiveField(3)
  int progressSeconds;

  @HiveField(4)
  int totalSeconds;

  @HiveField(5)
  DateTime lastWatched;

  WatchHistoryEntry({
    required this.movieId,
    required this.movieTitle,
    this.posterPath,
    required this.progressSeconds,
    required this.totalSeconds,
    required this.lastWatched,
  });

  double get progressPercent =>
      totalSeconds > 0 ? progressSeconds / totalSeconds : 0.0;
}
