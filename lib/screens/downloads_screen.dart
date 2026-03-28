import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import 'player_screen.dart';
import '../models/movie_model.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  final _dl = DownloadService();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Listen to all download updates
    _dl.addListener('*', (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _dl.removeListener('*');
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _dl.activeDownloads;
    final completed = _dl.completedDownloads;
    final all = _dl.allTasks;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('DOWNLOADS'),
        backgroundColor: AppTheme.bgPrimary,
        actions: [
          if (completed.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmDeleteAll,
              tooltip: 'Delete all downloads',
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Downloading (${active.length})'),
            Tab(text: 'Saved (${completed.length})'),
          ],
        ),
      ),
      body: all.isEmpty
          ? _buildEmpty()
          : TabBarView(
              controller: _tabs,
              children: [
                // Active downloads tab
                active.isEmpty
                    ? _buildEmptyTab('No active downloads',
                        Icons.download_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: active.length,
                        itemBuilder: (_, i) =>
                            _ActiveDownloadCard(task: active[i], dl: _dl),
                      ),

                // Completed downloads tab
                completed.isEmpty
                    ? _buildEmptyTab(
                        'No saved movies', Icons.movie_outlined)
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: completed.length,
                        itemBuilder: (_, i) =>
                            _CompletedDownloadCard(task: completed[i], dl: _dl),
                      ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_for_offline_outlined,
                color: AppTheme.accent, size: 52),
          ),
          const SizedBox(height: 24),
          const Text(
            'NO DOWNLOADS YET',
            style: TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 24,
              letterSpacing: 2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Download movies to watch offline\nwithout internet connection',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String msg, IconData icon) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 52),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 15,
                    color: AppTheme.textMuted)),
          ],
        ),
      );

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Delete All Downloads?',
            style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 22,
                letterSpacing: 1.5,
                color: AppTheme.textPrimary)),
        content: const Text(
          'This will delete all saved movies from your device.',
          style: TextStyle(fontFamily: 'DMSans', color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      for (final task in _dl.completedDownloads) {
        await _dl.deleteDownload(task.id);
      }
      setState(() {});
    }
  }
}

// ─── Active Download Card ─────────────────────────────────────────────────────
class _ActiveDownloadCard extends StatelessWidget {
  final DownloadTask task;
  final DownloadService dl;
  const _ActiveDownloadCard({required this.task, required this.dl});

  @override
  Widget build(BuildContext context) {
    final isPaused = task.status == DownloadStatus.paused;
    final isFailed = task.status == DownloadStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFailed
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: task.posterPath != null
                    ? CachedNetworkImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w92${task.posterPath}',
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 70,
                        color: AppTheme.bgElevated,
                        child: const Icon(Icons.movie,
                            color: AppTheme.textMuted)),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.movieTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _QualityBadge(quality: task.quality),
                        const SizedBox(width: 8),
                        Text(
                          isFailed
                              ? 'Failed'
                              : isPaused
                                  ? 'Paused'
                                  : '${(task.progress * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: isFailed
                                ? AppTheme.error
                                : AppTheme.textMuted,
                          ),
                        ),
                        if (!isFailed && task.totalBytes > 0) ...[
                          const Text(' • ',
                              style:
                                  TextStyle(color: AppTheme.textMuted)),
                          Text(
                            '${task.downloadedMB} / ${task.fileSizeMB}',
                            style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                color: AppTheme.textMuted),
                          ),
                        ],
                      ],
                    ),
                    if (isFailed && task.errorMessage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.errorMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            color: AppTheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFailed)
                    IconButton(
                      icon: Icon(
                          isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppTheme.accent),
                      onPressed: () {
                        if (isPaused) {
                          dl.resumeDownload(task.id);
                        } else {
                          dl.pauseDownload(task.id);
                        }
                      },
                    ),
                  if (isFailed)
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: AppTheme.accent),
                      onPressed: () => dl.resumeDownload(task.id),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppTheme.textMuted, size: 18),
                    onPressed: () => dl.cancelDownload(task.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.status == DownloadStatus.downloading
                  ? task.progress
                  : (isPaused ? task.progress : null),
              backgroundColor: AppTheme.bgElevated,
              valueColor: AlwaysStoppedAnimation(
                isFailed ? AppTheme.error : AppTheme.accent,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completed Download Card ──────────────────────────────────────────────────
class _CompletedDownloadCard extends StatelessWidget {
  final DownloadTask task;
  final DownloadService dl;
  const _CompletedDownloadCard({required this.task, required this.dl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: task.posterPath != null
              ? CachedNetworkImage(
                  imageUrl:
                      'https://image.tmdb.org/t/p/w92${task.posterPath}',
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 50,
                  height: 70,
                  color: AppTheme.bgElevated,
                  child: const Icon(Icons.movie,
                      color: AppTheme.textMuted)),
        ),
        title: Text(
          task.movieTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            _QualityBadge(quality: task.quality),
            const SizedBox(width: 8),
            Text(
              task.fileSizeMB,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: AppTheme.textMuted),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle,
                size: 12, color: AppTheme.success),
            const Text(' Saved',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    color: AppTheme.success)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play offline
            IconButton(
              icon: const Icon(Icons.play_circle_outline,
                  color: AppTheme.accent, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      movie: Movie(
                        id: task.movieId,
                        title: task.movieTitle,
                        posterPath: task.posterPath,
                      ),
                      source: StreamSource(
                        providerName: 'Downloaded',
                        url: task.savePath,
                        quality: task.quality,
                      ),
                      isOffline: true,
                    ),
                  ),
                );
              },
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.textMuted, size: 20),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.bgCard,
                    title: const Text('Delete Download?',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: AppTheme.textPrimary)),
                    content: Text(
                      'Delete "${task.movieTitle}" (${task.quality}) from your device?',
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
                if (ok == true) await dl.deleteDownload(task.id);
              },
            ),
          ],
        ),
        onTap: () {
          // Play offline
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                movie: Movie(
                  id: task.movieId,
                  title: task.movieTitle,
                  posterPath: task.posterPath,
                ),
                source: StreamSource(
                  providerName: 'Downloaded',
                  url: task.savePath,
                  quality: task.quality,
                ),
                isOffline: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Quality Badge ────────────────────────────────────────────────────────────
class _QualityBadge extends StatelessWidget {
  final String quality;
  const _QualityBadge({required this.quality});

  Color get _color {
    switch (quality) {
      case '4K': return const Color(0xFF6C63FF);
      case '1080p': return AppTheme.success;
      case '720p': return AppTheme.accent;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color.withOpacity(0.5)),
        ),
        child: Text(
          quality,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _color,
          ),
        ),
      );
}
