import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/tmdb_service.dart';
import '../models/movie_model.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tmdb = TmdbService();
  List<Movie> _watchlistMovies = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    if (StorageService.watchlist.isEmpty) return;
    setState(() => _loading = true);
    // We'd fetch each movie from TMDB using stored IDs
    // For now show from history
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final history = StorageService.watchHistory;
    final continueWatching = StorageService.continueWatching;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('MY VAULT'),
        backgroundColor: AppTheme.bgPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'DMSans', fontSize: 13),
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Continue Watching'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Continue Watching tab
          continueWatching.isEmpty
              ? _buildEmptyState('Nothing in progress',
                  'Start watching a movie to continue here')
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: continueWatching.length,
                  itemBuilder: (ctx, i) {
                    final entry = continueWatching[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: entry.posterPath != null
                                    ? Image.network(
                                        'https://image.tmdb.org/t/p/w300${entry.posterPath}',
                                        fit: BoxFit.cover,
                                      )
                                    : Container(color: AppTheme.bgCard),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(
                                  value: entry.progressPercent,
                                  backgroundColor: Colors.black45,
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          AppTheme.accent),
                                  minHeight: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.movieTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                        Text(
                          '${(entry.progressPercent * 100).round()}% watched',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: AppTheme.textMuted),
                        ),
                      ],
                    );
                  },
                ),

          // History tab
          history.isEmpty
              ? _buildEmptyState(
                  'No watch history', 'Movies you watch will appear here')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: history.length,
                  itemBuilder: (ctx, i) {
                    final entry = history[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: entry.posterPath != null
                                ? Image.network(
                                    'https://image.tmdb.org/t/p/w92${entry.posterPath}',
                                    width: 56,
                                    height: 78,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 78,
                                    color: AppTheme.bgElevated,
                                    child: const Icon(Icons.movie,
                                        color: AppTheme.textMuted),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.movieTitle,
                                    style: const TextStyle(
                                        fontFamily: 'DMSans',
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDuration(entry.progressSeconds),
                                  style: const TextStyle(
                                      fontFamily: 'DMSans',
                                      fontSize: 12,
                                      color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: entry.progressPercent,
                                  backgroundColor: AppTheme.bgElevated,
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                          AppTheme.accent),
                                  minHeight: 2,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.textMuted, size: 18),
                            onPressed: () async {
                              await StorageService.removeFromHistory(
                                  entry.movieId);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined,
              color: AppTheme.textMuted, size: 72),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 22,
                  letterSpacing: 1.5,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m watched';
    if (m > 0) return '${m}m ${s}s watched';
    return '${s}s watched';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
