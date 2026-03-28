import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/movie_model.dart';
import '../services/tmdb_service.dart';
import '../services/storage_service.dart';
import '../providers/stream_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import 'player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _tmdb = TmdbService();
  late Movie _movie;
  List<Movie> _similar = [];
  bool _inWatchlist = false;
  bool _loadingDetail = true;
  bool _loadingStreams = false;
  List<StreamSource> _streams = [];

  @override
  void initState() {
    super.initState();
    _movie = widget.movie;
    _inWatchlist = StorageService.isInWatchlist(_movie.id);
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _tmdb.getMovieDetail(
        _movie.id, isMovie: _movie.isMovie);
      final similar = await _tmdb.getSimilar(
        _movie.id, isMovie: _movie.isMovie);
      if (mounted) {
        setState(() {
          if (detail != null) _movie = detail;
          _similar = similar;
          _loadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  Future<void> _fetchStreams() async {
    setState(() => _loadingStreams = true);
    
    final streams = await ProviderRegistry.fetchAllStreams(
      _movie.title,
      _movie.year ?? 2024,
      imdbId: _movie.imdbId,
      isMovie: _movie.isMovie,
    );

    if (mounted) {
      setState(() {
        _streams = streams;
        _loadingStreams = false;
      });
      if (streams.isEmpty) {
        _showNoSourceDialog();
      } else {
        _showSourcePicker(streams);
      }
    }
  }

  void _showSourcePicker(List<StreamSource> sources) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SourcePickerSheet(
        sources: sources,
        onSelect: (source) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => PlayerScreen(
              movie: _movie,
              source: source,
            ),
          ));
        },
      ),
    );
  }

  void _showNoSourceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('No Sources Found',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'No streaming sources found for this title right now. Try again later or check back soon.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildOverview(),
                  const SizedBox(height: 24),
                  if (_movie.cast.isNotEmpty) ...[
                    _buildCast(),
                    const SizedBox(height: 24),
                  ],
                  if (_similar.isNotEmpty) ...[
                    _buildSimilar(),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: AppTheme.bgPrimary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_outlined, size: 18),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_movie.backdropUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: _movie.backdropUrl,
                fit: BoxFit.cover,
              )
            else
              Container(color: AppTheme.bgCard),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    AppTheme.bgPrimary.withOpacity(0.8),
                    AppTheme.bgPrimary,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Play button center
            Center(
              child: GestureDetector(
                onTap: _fetchStreams,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          _movie.title,
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 34,
            letterSpacing: 2,
            color: AppTheme.textPrimary,
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

        if (_movie.tagline != null && _movie.tagline!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '"${_movie.tagline}"',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.textMuted,
            ),
          ),
        ],

        const SizedBox(height: 12),
        // Meta row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (_movie.year != null)
              _MetaChip(text: '${_movie.year}'),
            if (_movie.runtimeFormatted.isNotEmpty)
              _MetaChip(text: _movie.runtimeFormatted),
            if (_movie.status != null)
              _MetaChip(
                text: _movie.status!,
                color: _movie.isUpcoming
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
            ..._movie.genres.take(3).map((g) => _MetaChip(text: g)),
          ],
        ),

        const SizedBox(height: 12),
        // Rating
        if (_movie.voteAverage != null)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.imdbColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Colors.black),
                    const SizedBox(width: 3),
                    Text(
                      _movie.ratingFormatted,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_movie.voteCount != null)
                Text(
                  '${_formatCount(_movie.voteCount!)} votes',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Watch Now Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadingStreams ? null : _fetchStreams,
            icon: _loadingStreams
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 22),
            label: Text(
              _loadingStreams ? 'Finding Sources...' : 'WATCH NOW',
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Watchlist
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await StorageService.toggleWatchlist(_movie);
                  setState(() => _inWatchlist = !_inWatchlist);
                },
                icon: Icon(
                  _inWatchlist ? Icons.bookmark : Icons.bookmark_border,
                  color: _inWatchlist ? AppTheme.accent : AppTheme.textSecondary,
                  size: 18,
                ),
                label: Text(
                  _inWatchlist ? 'Saved' : 'My List',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: _inWatchlist
                        ? AppTheme.accent
                        : AppTheme.textSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _inWatchlist
                        ? AppTheme.accent
                        : AppTheme.divider,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Trailer
            if (_movie.trailerKey != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Open YouTube trailer
                  },
                  icon: const Icon(Icons.ondemand_video_outlined,
                      color: AppTheme.textSecondary, size: 18),
                  label: const Text('Trailer',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          color: AppTheme.textSecondary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview() {
    if (_movie.overview == null || _movie.overview!.isEmpty) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Story',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 20,
              letterSpacing: 1.5,
              color: AppTheme.textPrimary,
            )),
        const SizedBox(height: 8),
        Text(
          _movie.overview!,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
          maxLines: 5,
          overflow: TextOverflow.fade,
        ),
      ],
    );
  }

  Widget _buildCast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cast',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 20,
              letterSpacing: 1.5,
              color: AppTheme.textPrimary,
            )),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _movie.cast.length,
            itemBuilder: (ctx, i) {
              final c = _movie.cast[i];
              return Container(
                width: 72,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: c.profileUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: c.profileUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 64,
                              height: 64,
                              color: AppTheme.bgCard,
                              child: const Icon(Icons.person,
                                  color: AppTheme.textMuted),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More Like This',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 20,
              letterSpacing: 1.5,
              color: AppTheme.textPrimary,
            )),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _similar.length,
            itemBuilder: (ctx, i) => MovieCard(
              movie: _similar[i],
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        MovieDetailScreen(movie: _similar[i])),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─── Source Picker Bottom Sheet ───────────────────────────────────────────────
class _SourcePickerSheet extends StatelessWidget {
  final List<StreamSource> sources;
  final Function(StreamSource) onSelect;

  const _SourcePickerSheet({required this.sources, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'SELECT SOURCE',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 20,
              letterSpacing: 2,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${sources.length} sources found',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...sources.map((s) => GestureDetector(
            onTap: () => onSelect(s),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _qualityColor(s.quality),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.quality,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.providerName,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (s.subtitle != null)
                          Text(s.subtitle!,
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_outline,
                      color: AppTheme.accent, size: 28),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _qualityColor(String quality) {
    switch (quality) {
      case '4K': return const Color(0xFF6C63FF);
      case '1080p': return const Color(0xFF00C853);
      case '720p': return AppTheme.accent;
      default: return AppTheme.textMuted;
    }
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final String text;
  final Color? color;
  const _MetaChip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color ?? AppTheme.divider),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          color: color ?? AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
