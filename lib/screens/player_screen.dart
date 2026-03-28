import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/movie_model.dart';
import '../services/storage_service.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Movie movie;
  final StreamSource source;
  final bool isOffline;

  const PlayerScreen({
    super.key,
    required this.movie,
    required this.source,
    this.isOffline = false,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _controller;
  bool _hasError = false;
  String _errorMessage = '';
  final _dl = DownloadService();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _initPlayer();
  }

  void _initPlayer() {
    final url = widget.source.url;
    final startAt = StorageService.getProgress(widget.movie.id);

    BetterPlayerDataSource dataSource;
    if (widget.isOffline) {
      dataSource = BetterPlayerDataSource(BetterPlayerDataSourceType.file, url);
    } else if (url.contains('.m3u8')) {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, url,
        videoFormat: BetterPlayerVideoFormat.hls,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://google.com',
        },
      );
    } else {
      dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, url,
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
      );
    }

    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        allowedScreenSleep: false,
        startAt: startAt > 0 ? Duration(seconds: startAt) : Duration.zero,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: true,
          enableProgressBar: true,
          enablePlayPause: true,
          enableSkips: true,
          enableMute: true,
          enableAudioTracks: true,
          enableSubtitles: true,
          enableQualities: true,
          skipForwardTimeInMilliseconds: 10000,
          skipBackTimeInMilliseconds: 10000,
          controlBarColor: Colors.black87,
          iconsColor: Colors.white,
          progressBarPlayedColor: AppTheme.accent,
          progressBarBufferedColor: AppTheme.accent.withOpacity(0.35),
          progressBarBackgroundColor: Colors.white24,
          textColor: Colors.white,
          loadingColor: AppTheme.accent,
          overflowModalColor: AppTheme.bgCard,
          overflowModalTextColor: AppTheme.textPrimary,
          overflowMenuIconsColor: AppTheme.accent,
        ),
        eventListener: (event) {
          if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
            if (mounted) setState(() { _hasError = true; _errorMessage = event.parameters?['exception']?.toString() ?? 'Playback failed'; });
          }
          if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
            _saveProgress();
          }
        },
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  Future<void> _saveProgress() async {
    try {
      final pos = await _controller?.videoPlayerController?.position;
      final dur = _controller?.videoPlayerController?.value.duration;
      if (pos != null && dur != null && dur.inSeconds > 0) {
        await StorageService.updateProgress(widget.movie.id, widget.movie.title, widget.movie.posterPath, pos.inSeconds, dur.inSeconds);
      }
    } catch (_) {}
  }

  void _showDownloadOptions() {
    if (_dl.isDownloaded(widget.movie.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already downloaded! Check Downloads tab.'), backgroundColor: AppTheme.success));
      return;
    }
    if (_dl.isDownloading(widget.movie.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already downloading...'), backgroundColor: AppTheme.bgCard));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DownloadSheet(
        movie: widget.movie,
        currentUrl: widget.source.url,
        currentQuality: widget.source.quality,
        onDownload: (quality, url) async {
          Navigator.pop(context);
          await _dl.startDownload(movieId: widget.movie.id, movieTitle: widget.movie.title, posterPath: widget.movie.posterPath, url: url, quality: quality);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading "${widget.movie.title}" in $quality'), backgroundColor: AppTheme.accent, duration: const Duration(seconds: 3)),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _saveProgress();
    _controller?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_hasError && _controller != null)
            SizedBox.expand(child: BetterPlayer(controller: _controller!))
          else if (_hasError)
            _buildError()
          else
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 6, left: 4, right: 12, bottom: 12),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent])),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(widget.movie.title, style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 18, letterSpacing: 1.5, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${widget.source.providerName} · ${widget.source.quality}${widget.isOffline ? " · Offline" : ""}', style: const TextStyle(fontFamily: 'DMSans', fontSize: 11, color: Colors.white70)),
            ]),
          ),
          if (!widget.isOffline)
            IconButton(icon: const Icon(Icons.download_rounded, color: Colors.white, size: 24), onPressed: _showDownloadOptions, tooltip: 'Download'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 64),
          const SizedBox(height: 20),
          const Text('PLAYBACK FAILED', style: TextStyle(fontFamily: 'BebasNeue', fontSize: 26, letterSpacing: 2, color: Colors.white)),
          const SizedBox(height: 8),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: Colors.white60)),
          const SizedBox(height: 28),
          ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('Try Another Source'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
        ]),
      ),
    );
  }
}

class _DownloadSheet extends StatelessWidget {
  final Movie movie;
  final String currentUrl;
  final String currentQuality;
  final Function(String, String) onDownload;

  const _DownloadSheet({required this.movie, required this.currentUrl, required this.currentQuality, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'q': '1080p', 'label': 'Full HD · 1080p', 'size': '~1.5 GB', 'color': const Color(0xFF00C853)},
      {'q': '720p', 'label': 'HD · 720p', 'size': '~800 MB', 'color': AppTheme.accent},
      {'q': '480p', 'label': 'SD · 480p', 'size': '~400 MB', 'color': const Color(0xFF888888)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          const Icon(Icons.download_for_offline_outlined, color: AppTheme.accent, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DOWNLOAD MOVIE', style: TextStyle(fontFamily: 'BebasNeue', fontSize: 22, letterSpacing: 2, color: AppTheme.textPrimary)),
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.textSecondary)),
          ])),
        ]),
        const SizedBox(height: 6),
        const Text('Choose quality — saved to your device for offline watching', style: TextStyle(fontFamily: 'DMSans', fontSize: 13, color: AppTheme.textMuted)),
        const SizedBox(height: 20),
        ...options.map((opt) {
          final color = opt['color'] as Color;
          return GestureDetector(
            onTap: () => onDownload(opt['q'] as String, currentUrl),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: opt['q'] == currentQuality ? AppTheme.accent : AppTheme.divider),
              ),
              child: Row(children: [
                Container(
                  width: 56, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.5))),
                  child: Text(opt['q'] as String, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'DMSans', fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(opt['label'] as String, style: const TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text('Approx. ${opt['size']}', style: const TextStyle(fontFamily: 'DMSans', fontSize: 12, color: AppTheme.textMuted)),
                ])),
                Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle), child: const Icon(Icons.download_rounded, color: Colors.white, size: 18)),
              ]),
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.bgElevated, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
            SizedBox(width: 8),
            Expanded(child: Text('Saved to device storage. Manage in Downloads tab.', style: TextStyle(fontFamily: 'DMSans', fontSize: 11, color: AppTheme.textMuted, height: 1.4))),
          ]),
        ),
      ]),
    );
  }
}
