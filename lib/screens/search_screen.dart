import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/movie_model.dart';
import '../services/tmdb_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _tmdb = TmdbService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<Movie> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String _query = '';

  // Filters
  String _selectedType = 'All';
  String _selectedYear = 'Any';
  String _selectedGenre = 'Any';

  final _types = ['All', 'Movies', 'TV Shows'];
  final _years = ['Any', '2024', '2023', '2022', '2021', '2020', '2019', '2018', 'Older'];
  final _genres = [
    'Any', 'Action', 'Comedy', 'Drama', 'Horror', 'Thriller',
    'Romance', 'Sci-Fi', 'Animation', 'Documentary', 'Fantasy',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final q = _controller.text.trim();
    if (q == _query) return;
    _query = q;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (q.isEmpty) {
      setState(() { _results = []; _hasSearched = false; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String query) async {
    try {
      final results = await _tmdb.search(query);
      if (mounted && _controller.text.trim() == query) {
        setState(() {
          _results = results;
          _isSearching = false;
          _hasSearched = true;
        });
        StorageService.addRecentSearch(query);
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  List<Movie> get _filteredResults {
    var results = _results;
    if (_selectedType == 'Movies') results = results.where((m) => m.isMovie).toList();
    if (_selectedType == 'TV Shows') results = results.where((m) => !m.isMovie).toList();
    if (_selectedYear != 'Any') {
      if (_selectedYear == 'Older') {
        results = results.where((m) => m.year != null && m.year! < 2018).toList();
      } else {
        final yr = int.tryParse(_selectedYear);
        if (yr != null) results = results.where((m) => m.year == yr).toList();
      }
    }
    if (_selectedGenre != 'Any') {
      results = results.where((m) => m.genres.any(
        (g) => g.toLowerCase().contains(_selectedGenre.toLowerCase())
      )).toList();
    }
    return results;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
            color: AppTheme.textPrimary,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: AppTheme.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search movies, shows...',
                hintStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    color: AppTheme.textMuted,
                    fontSize: 15),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.accent),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.accent),
                        ),
                      )
                    else if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() { _results = []; _hasSearched = false; });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.mic_outlined,
                          color: AppTheme.textSecondary, size: 22),
                      onPressed: () {}, // Voice search placeholder
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    if (!_hasSearched && _results.isEmpty) return const SizedBox();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterDropdown(
            label: _selectedType,
            options: _types,
            onSelect: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(width: 8),
          _FilterDropdown(
            label: 'Year: $_selectedYear',
            options: _years,
            onSelect: (v) => setState(() => _selectedYear = v),
          ),
          const SizedBox(width: 8),
          _FilterDropdown(
            label: 'Genre: $_selectedGenre',
            options: _genres,
            onSelect: (v) => setState(() => _selectedGenre = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched && _results.isEmpty) {
      return _buildRecentSearches();
    }

    final filtered = _filteredResults;

    if (filtered.isEmpty && _hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: AppTheme.textMuted, size: 64),
            const SizedBox(height: 16),
            Text(
              'No results for "$_query"',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search or adjust filters',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            '${filtered.length} results',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.58,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => MovieCard(
              movie: filtered[i],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MovieDetailScreen(movie: filtered[i])),
              ),
            ).animate(delay: Duration(milliseconds: i * 30)).fadeIn(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    final recent = StorageService.recentSearches;
    if (recent.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter_outlined,
                color: AppTheme.textMuted, size: 72),
            SizedBox(height: 16),
            Text(
              'Search any movie or show',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 22,
                letterSpacing: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Find worldwide content from all providers',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches',
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 18,
                    letterSpacing: 1.5,
                    color: AppTheme.textPrimary,
                  )),
              TextButton(
                onPressed: () async {
                  await StorageService.clearRecentSearches();
                  setState(() {});
                },
                child: const Text('Clear All',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        color: AppTheme.accent)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: recent.length,
          itemBuilder: (ctx, i) => ListTile(
            leading: const Icon(Icons.history, color: AppTheme.textMuted),
            title: Text(recent[i],
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: AppTheme.textSecondary)),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
              onPressed: () async {
                final searches = StorageService.recentSearches;
                searches.remove(recent[i]);
                await StorageService.clearRecentSearches();
                for (final s in searches) await StorageService.addRecentSearch(s);
                setState(() {});
              },
            ),
            onTap: () {
              _controller.text = recent[i];
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: recent[i].length));
            },
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final Function(String) onSelect;
  const _FilterDropdown({required this.label, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.bgCard,
        builder: (_) => ListView(
          shrinkWrap: true,
          children: options.map((o) => ListTile(
            title: Text(o, style: const TextStyle(
                fontFamily: 'DMSans', color: AppTheme.textPrimary)),
            onTap: () { Navigator.pop(context); onSelect(o); },
          )).toList(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 12,
                color: AppTheme.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 14, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
