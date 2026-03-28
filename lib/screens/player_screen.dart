import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
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

  Future<void> _initPlayer() async {
    try {
      final url = widget.source.url;
      final startAt = StorageService.getProgress(widget.movie.id);

      if (widget.isOffline) {
        _videoController = VideoPlayerController.contentUri(
          Uri.parse(url),
        );
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(url),
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://google.com',
          },
        );
      }

      await _videoController!.initialize();

      if (startAt > 0) {
        await _videoController!.seekTo(Duration(seconds: startAt));
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.accent,
          handleColor: AppTheme.accent,
          backgroundColor: Colors.white24,
          bufferedColor: AppTheme.accent.withOpacity(0.3),
        ),
      );

      _videoController!.addListener(_progressListener);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _progressListener() {
    final pos = _videoController?.value.position;
    final dur = _videoController?.value.duration;
    if (pos != null && dur != null && dur.inSeconds > 0) {
      if (pos.inSeconds % 10 == 0) {
        StorageService.updateProgress(
          widget.movie.id,
          widget.movie.title,
          widget.movie.posterPath,
          pos.inSeconds,
          dur.inSeconds,
        );
      }
    }
  }

  void _showDownloadOptions() {
    if (_dl.isDownloaded(widget.movie.id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Already downloaded! Check Downloads tab.'),
        backgroundColor: AppTheme.success,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DownloadSheet(
        movie: widget.movie,
        currentUrl: widget.source.url,
        currentQuality: widget.source.quality,
        onDownload: (quality, url) async {
          Navigator.pop(context);
          await _dl.startDownload(
            movieId: widget.movie.id,
            movieTitle: widget.movie.title,
            posterPath: widget.movie.posterPath,
            url: url,
            quality: quality,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Downloading in $quality...'),
              backgroundColor: AppTheme.accent,
            ));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.removeListener(_progressListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_hasError)
            _buildError()
          else if (_chewieController != null)
            SizedBox.expand(child: Chewie(controller: _chewieController!))
          else
            const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildTopBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 4, right: 12, bottom: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.movie.title,
              style: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 18,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!widget.isOffline)
            IconButton(
              icon: const Icon(Icons.download_rounded,
                  color: Colors.white, size: 24),
              onPressed: _showDownloadOptions,
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.error, size: 64),
            const SizedBox(height: 20),
            const Text('PLAYBACK FAILED',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 26,
                  letterSpacing: 2,
                  color: Colors.white,
                )),
            const SizedBox(height: 8),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Try Another Source'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadSheet extends StatelessWidget {
  final Movie movie;
  final String currentUrl;
  final String currentQuality;
  final Function(String, String) onDownload;

  const _DownloadSheet({
    required this.movie,
    required this.currentUrl,
    required this.currentQuality,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      {'q': '1080p', 'label': 'Full HD · 1080p', 'size': '~1.5 GB'},
      {'q': '720p', 'label': 'HD · 720p', 'size': '~800 MB'},
      {'q': '480p', 'label': 'SD · 480p', 'size': '~400 MB'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('DOWNLOAD MOVIE',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 22,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
              )),
          const SizedBox(height: 6),
          const Text('Choose quality for offline viewing',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...options.map((opt) => GestureDetector(
            onTap: () => onDownload(opt['q']!, currentUrl),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: opt['q'] == currentQuality
                      ? AppTheme.accent
                      : AppTheme.divider,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opt['label']!,
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            )),
                        Text('Approx. ${opt['size']}',
                            style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 12,
                                color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
