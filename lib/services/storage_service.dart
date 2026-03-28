import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie_model.dart';

class StorageService {
  static const String _watchlistBox = 'watchlist';
  static const String _historyBox = 'watch_history';
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'movie_cache';

  static late Box<String> _watchlistStore;
  static late Box<WatchHistoryEntry> _historyStore;
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(WatchHistoryEntryAdapter());
    
    _watchlistStore = await Hive.openBox<String>(_watchlistBox);
    _historyStore = await Hive.openBox<WatchHistoryEntry>(_historyBox);
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── WATCHLIST ──────────────────────────────────────────
  static List<String> get watchlist =>
      _watchlistStore.values.toList();

  static bool isInWatchlist(String movieId) =>
      _watchlistStore.containsKey(movieId);

  static Future<void> addToWatchlist(Movie movie) async {
    await _watchlistStore.put(movie.id, movie.id);
    await _cacheMovie(movie);
  }

  static Future<void> removeFromWatchlist(String movieId) async {
    await _watchlistStore.delete(movieId);
  }

  static Future<void> toggleWatchlist(Movie movie) async {
    if (isInWatchlist(movie.id)) {
      await removeFromWatchlist(movie.id);
    } else {
      await addToWatchlist(movie);
    }
  }

  // ─── WATCH HISTORY ──────────────────────────────────────
  static List<WatchHistoryEntry> get watchHistory {
    final entries = _historyStore.values.toList();
    entries.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    return entries;
  }

  static List<WatchHistoryEntry> get continueWatching {
    return watchHistory
        .where((e) => e.progressPercent > 0.05 && e.progressPercent < 0.95)
        .take(10)
        .toList();
  }

  static Future<void> updateProgress(
    String movieId,
    String title,
    String? posterPath,
    int progressSeconds,
    int totalSeconds,
  ) async {
    final existing = _historyStore.get(movieId);
    if (existing != null) {
      existing.progressSeconds = progressSeconds;
      existing.totalSeconds = totalSeconds;
      existing.lastWatched = DateTime.now();
      await existing.save();
    } else {
      await _historyStore.put(
        movieId,
        WatchHistoryEntry(
          movieId: movieId,
          movieTitle: title,
          posterPath: posterPath,
          progressSeconds: progressSeconds,
          totalSeconds: totalSeconds,
          lastWatched: DateTime.now(),
        ),
      );
    }
  }

  static int getProgress(String movieId) {
    return _historyStore.get(movieId)?.progressSeconds ?? 0;
  }

  static Future<void> clearHistory() async {
    await _historyStore.clear();
  }

  static Future<void> removeFromHistory(String movieId) async {
    await _historyStore.delete(movieId);
  }

  // ─── SETTINGS ───────────────────────────────────────────
  static String get defaultQuality =>
      _prefs.getString('default_quality') ?? 'Auto';

  static Future<void> setDefaultQuality(String q) async {
    await _prefs.setString('default_quality', q);
  }

  static bool get autoPlayNext =>
      _prefs.getBool('auto_play_next') ?? true;

  static Future<void> setAutoPlayNext(bool v) async {
    await _prefs.setBool('auto_play_next', v);
  }

  static String get appLanguage =>
      _prefs.getString('app_language') ?? 'en';

  static Future<void> setAppLanguage(String lang) async {
    await _prefs.setString('app_language', lang);
  }

  static List<String> get disabledProviders =>
      _prefs.getStringList('disabled_providers') ?? [];

  static Future<void> setDisabledProviders(List<String> providers) async {
    await _prefs.setStringList('disabled_providers', providers);
  }

  static bool isProviderEnabled(String providerName) =>
      !disabledProviders.contains(providerName);

  static String get subtitleSize =>
      _prefs.getString('subtitle_size') ?? 'medium';

  static Future<void> setSubtitleSize(String s) async {
    await _prefs.setString('subtitle_size', s);
  }

  // ─── RECENT SEARCHES ────────────────────────────────────
  static List<String> get recentSearches =>
      _prefs.getStringList('recent_searches') ?? [];

  static Future<void> addRecentSearch(String query) async {
    final searches = recentSearches;
    searches.remove(query);
    searches.insert(0, query);
    await _prefs.setStringList(
        'recent_searches', searches.take(10).toList());
  }

  static Future<void> clearRecentSearches() async {
    await _prefs.remove('recent_searches');
  }

  // ─── MOVIE CACHE ────────────────────────────────────────
  static Future<void> _cacheMovie(Movie movie) async {
    // Simple JSON cache via SharedPreferences
    final key = 'movie_${movie.id}';
    await _prefs.setString(key, movie.id); // Store IDs for now
  }

  static Future<void> clearCache() async {
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith('movie_'))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // ─── ADMIN SETTINGS ─────────────────────────────────────
  static bool get isAdmin => _prefs.getBool('is_admin') ?? false;
  
  static Future<bool> unlockAdmin(String pin) async {
    const adminPin = '7749'; // Change this
    if (pin == adminPin) {
      await _prefs.setBool('is_admin', true);
      return true;
    }
    return false;
  }

  static Future<void> lockAdmin() async {
    await _prefs.setBool('is_admin', false);
  }

  static List<String> get featuredMovieIds =>
      _prefs.getStringList('featured_movies') ?? [];

  static Future<void> setFeaturedMovies(List<String> ids) async {
    await _prefs.setStringList('featured_movies', ids);
  }

  static List<String> get blacklistedMovieIds =>
      _prefs.getStringList('blacklisted_movies') ?? [];

  static Future<void> blacklistMovie(String id) async {
    final list = blacklistedMovieIds;
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList('blacklisted_movies', list);
    }
  }
}
