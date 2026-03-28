import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/movie_model.dart';
import '../services/tmdb_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_loader.dart';
import 'movie_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tmdb = TmdbService();
  final _scrollController = ScrollController();

  List<Movie> _bannerMovies = [];
  List<Movie> _trending = [];
  List<Movie> _continueWatching = [];
  List<Movie> _popularMovies = [];
  List<Movie> _topRated = [];
  List<Movie> _upcoming = [];
  List<Movie> _bollywood = [];
  List<Movie> _korean = [];
  List<Movie> _anime = [];

  bool _isLoading = true;
  int _bannerIndex = 0;

  final List<Map<String, dynamic>> _ottPlatforms = [
    {'name': 'All', 'icon': '🎬', 'color': AppTheme.accent},
    {'name': 'Netflix', 'icon': 'N', 'color': const Color(0xFFE50914)},
    {'name': 'Hotstar', 'icon': '★', 'color': const Color(0xFF1F80E0)},
    {'name': 'JioCinema', 'icon': 'J', 'color': const Color(0xFF8B5CF6)},
    {'name': 'SonyLiv', 'icon': 'S', 'color': const Color(0xFF2196F3)},
    {'name': 'Zee5', 'icon': 'Z', 'color': const Color(0xFF9C27B0)},
    {'name': 'Amazon', 'icon': '▶', 'color': const Color(0xFF00A8E1)},
    {'name': 'MXPlayer', 'icon': 'M', 'color': const Color(0xFF00BCD4)},
  ];

  String _selectedOtt = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _tmdb.getTrending(),
        _tmdb.getPopularMovies(),
        _tmdb.getTopRated(),
        _tmdb.getUpcoming(),
        _tmdb.getByGenre(35), // Comedy (Bollywood proxy)
        _tmdb.getByGenre(18, isMovie: false), // Drama (Korean proxy)
        _tmdb.getByGenre(16, isMovie: false), // Animation (Anime)
      ]);

      if (mounted) {
        setState(() {
          _trending = results[0];
          _bannerMovies = results[0].take(5).toList();
          _popularMovies = results[1];
          _topRated = results[2];
          _upcoming = results[3];
          _bollywood = results[4];
          _korean = results[5];
          _anime = results[6];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
    _loadContinueWatching();
  }

  void _loadContinueWatching() {
    // Load from local storage — no server needed
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: RefreshIndicator(
        color: AppTheme.accent,
        backgroundColor: AppTheme.bgCard,
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadData();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              SliverToBoxAdapter(child: ShimmerLoader())
            else ...[
              // Hero Banner
              SliverToBoxAdapter(child: _buildHeroBanner()),
              // OTT Filter Row
              SliverToBoxAdapter(child: _buildOttRow()),
              // Continue Watching
              if (StorageService.continueWatching.isNotEmpty)
                SliverToBoxAdapter(child: _buildContinueWatching()),
              // Trending
              SliverToBoxAdapter(
                child: _buildMovieRow('🔥 Trending Now', _trending),
              ),
              // Popular
              SliverToBoxAdapter(
                child: _buildMovieRow('🎬 Popular Movies', _popularMovies),
              ),
              // Upcoming with countdown
              SliverToBoxAdapter(child: _buildUpcomingRow()),
              // Top Rated
              SliverToBoxAdapter(
                child: _buildMovieRow('⭐ Top Rated', _topRated),
              ),
              // Bollywood
              SliverToBoxAdapter(
                child: _buildMovieRow('🇮🇳 Bollywood', _bollywood),
              ),
              // Korean
              SliverToBoxAdapter(
                child: _buildMovieRow('🇰🇷 K-Drama & Korean', _korean),
              ),
              // Anime
              SliverToBoxAdapter(
                child: _buildMovieRow('⛩️ Anime', _anime),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppTheme.bgPrimary.withOpacity(0.95),
      elevation: 0,
      title: Row(
        children: [
          const Text(
            'CINE',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 26,
              color: AppTheme.textPrimary,
              letterSpacing: 3,
            ),
          ),
          Text(
            'VAULT',
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 26,
              color: AppTheme.accent,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 26),
          onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, size: 26),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroBanner() {
    if (_bannerMovies.isEmpty) return const SizedBox();
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 480,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (i, _) => setState(() => _bannerIndex = i),
          ),
          items: _bannerMovies.map((movie) => _BannerItem(
            movie: movie,
            onPlay: () => _openDetail(movie),
          )).toList(),
        ),
        const SizedBox(height: 12),
        AnimatedSmoothIndicator(
          activeIndex: _bannerIndex,
          count: _bannerMovies.length,
          effect: const WormEffect(
            dotWidth: 8,
            dotHeight: 4,
            activeDotColor: AppTheme.accent,
            dotColor: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOttRow() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _ottPlatforms.length,
        itemBuilder: (ctx, i) {
          final ott = _ottPlatforms[i];
          final isSelected = _selectedOtt == ott['name'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedOtt = ott['name']);
              if (ott['name'] != 'All') {
                _tmdb.getByOTT(ott['name']).then((movies) {
                  setState(() => _popularMovies = movies);
                });
              } else {
                _tmdb.getPopularMovies().then((movies) {
                  setState(() => _popularMovies = movies);
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (ott['color'] as Color)
                    : AppTheme.bgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (ott['color'] as Color)
                      : AppTheme.divider,
                  width: 1,
                ),
              ),
              child: Text(
                ott['name'],
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueWatching() {
    final entries = StorageService.continueWatching;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '▶ Continue Watching'),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final entry = entries[i];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: entry.posterPath != null
                              ? Image.network(
                                  'https://image.tmdb.org/t/p/w300${entry.posterPath}',
                                  height: 120,
                                  width: 160,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 120,
                                  width: 160,
                                  color: AppTheme.bgCard,
                                  child: const Icon(Icons.movie,
                                      color: AppTheme.textMuted),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: entry.progressPercent,
                            backgroundColor: Colors.black54,
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.accent),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.movieTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMovieRow(String title, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onMoreTap: () {},
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (ctx, i) => MovieCard(
              movie: movies[i],
              onTap: () => _openDetail(movies[i]),
            ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.1),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildUpcomingRow() {
    final upcomingFiltered =
        _upcoming.where((m) => m.isUpcoming).toList();
    if (upcomingFiltered.isEmpty) return _buildMovieRow('🗓 Upcoming', _upcoming);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '🗓 Coming Soon'),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: upcomingFiltered.length,
            itemBuilder: (ctx, i) {
              final movie = upcomingFiltered[i];
              return GestureDetector(
                onTap: () => _openDetail(movie),
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: movie.posterUrl.isNotEmpty
                                ? Image.network(
                                    movie.posterUrl,
                                    height: 180,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 180,
                                    width: 150,
                                    color: AppTheme.bgCard,
                                  ),
                          ),
                          if (movie.timeUntilRelease != null)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: CountdownTimer(
                                      duration: movie.timeUntilRelease!),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _openDetail(Movie movie) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MovieDetailScreen(movie: movie),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// ─── Banner Item ─────────────────────────────────────────────────────────────
class _BannerItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onPlay;
  const _BannerItem({required this.movie, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop
          movie.backdropUrl.isNotEmpty
              ? Image.network(movie.backdropUrl, fit: BoxFit.cover)
              : Container(color: AppTheme.bgCard),
          // Gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.bgPrimary.withOpacity(0.4),
                  AppTheme.bgPrimary.withOpacity(0.9),
                  AppTheme.bgPrimary,
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre chips
                if (movie.genres.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: movie.genres.take(3).map((g) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(g,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                    )).toList(),
                  ),
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 32,
                    letterSpacing: 2,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.imdbColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.black),
                          const SizedBox(width: 3),
                          Text(
                            movie.ratingFormatted,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (movie.year != null)
                      Text('${movie.year}',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    if (movie.runtimeFormatted.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(movie.runtimeFormatted,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('WATCH NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18,
                          color: AppTheme.textPrimary),
                      label: const Text('My List',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              color: AppTheme.textPrimary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.textSecondary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Countdown timer widget
class CountdownTimer extends StatefulWidget {
  final Duration duration;
  const CountdownTimer({super.key, required this.duration});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    if (days > 0) {
      return Text(
        '$days days',
        style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white),
      );
    }
    final hours = _remaining.inHours;
    return Text(
      '${hours}h left',
      style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white),
    );
  }
}
