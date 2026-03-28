import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum DownloadStatus { queued, downloading, completed, failed, paused }

class DownloadTask {
  final String id; // movieId + quality
  final String movieId;
  final String movieTitle;
  final String? posterPath;
  final String url;
  final String quality;
  String savePath;
  DownloadStatus status;
  double progress; // 0.0 to 1.0
  int downloadedBytes;
  int totalBytes;
  DateTime startedAt;
  String? errorMessage;
  CancelToken? cancelToken;

  DownloadTask({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    this.posterPath,
    required this.url,
    required this.quality,
    required this.savePath,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    DateTime? startedAt,
    this.errorMessage,
    this.cancelToken,
  }) : startedAt = startedAt ?? DateTime.now();

  String get fileSizeMB {
    if (totalBytes == 0) return '...';
    return '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String get downloadedMB {
    return '${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'posterPath': posterPath,
        'url': url,
        'quality': quality,
        'savePath': savePath,
        'status': status.name,
        'progress': progress,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'startedAt': startedAt.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id'],
        movieId: json['movieId'],
        movieTitle: json['movieTitle'],
        posterPath: json['posterPath'],
        url: json['url'],
        quality: json['quality'],
        savePath: json['savePath'],
        status: DownloadStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DownloadStatus.failed,
        ),
        progress: (json['progress'] as num).toDouble(),
        downloadedBytes: json['downloadedBytes'] ?? 0,
        totalBytes: json['totalBytes'] ?? 0,
        startedAt: DateTime.tryParse(json['startedAt'] ?? '') ?? DateTime.now(),
        errorMessage: json['errorMessage'],
      );
}

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(hours: 2),
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
  ));

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, Function(DownloadTask)> _listeners = {};

  static const String _storageKey = 'download_tasks';

  // ─── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadTasksFromStorage();
    // Resume incomplete downloads on restart
    for (final task in _tasks.values) {
      if (task.status == DownloadStatus.downloading) {
        task.status = DownloadStatus.paused;
      }
    }
    await _saveTasksToStorage();
  }

  // ─── GET DOWNLOAD DIR ──────────────────────────────────────────────────────
  Future<String> get _downloadDir async {
    Directory dir;
    try {
      // Try external storage first (Movies folder)
      final extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.movies);
      if (extDirs != null && extDirs.isNotEmpty) {
        dir = Directory('${extDirs.first.path}/CineVault');
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        dir = Directory('${appDir.path}/Downloads');
      }
    } catch (_) {
      final appDir = await getApplicationDocumentsDirectory();
      dir = Directory('${appDir.path}/Downloads');
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  // ─── START DOWNLOAD ────────────────────────────────────────────────────────
  Future<DownloadTask?> startDownload({
    required String movieId,
    required String movieTitle,
    String? posterPath,
    required String url,
    required String quality,
  }) async {
    final taskId = '${movieId}_$quality';

    // Check if already downloading or completed
    if (_tasks.containsKey(taskId)) {
      final existing = _tasks[taskId]!;
      if (existing.status == DownloadStatus.completed) {
        return existing; // Already downloaded
      }
      if (existing.status == DownloadStatus.downloading) {
        return existing; // Already in progress
      }
    }

    final dir = await _downloadDir;
    final safeTitle = movieTitle
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(' ', '_');
    final ext = url.contains('.m3u8') ? 'ts' : 'mp4';
    final savePath = '$dir/${safeTitle}_$quality.$ext';

    final cancelToken = CancelToken();
    final task = DownloadTask(
      id: taskId,
      movieId: movieId,
      movieTitle: movieTitle,
      posterPath: posterPath,
      url: url,
      quality: quality,
      savePath: savePath,
      status: DownloadStatus.downloading,
      cancelToken: cancelToken,
    );

    _tasks[taskId] = task;
    await _saveTasksToStorage();
    _notifyListener(taskId, task);

    // Start download in background
    _downloadFile(task);

    return task;
  }

  // ─── DOWNLOAD FILE ─────────────────────────────────────────────────────────
  Future<void> _downloadFile(DownloadTask task) async {
    try {
      await _dio.download(
        task.url,
        task.savePath,
        cancelToken: task.cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          task.downloadedBytes = received;
          task.totalBytes = total > 0 ? total : received;
          task.progress = total > 0 ? received / total : 0.0;
          task.status = DownloadStatus.downloading;
          _notifyListener(task.id, task);
          _saveTasksToStorage(); // Persist progress
        },
      );

      // Verify file exists
      final file = File(task.savePath);
      if (await file.exists() && await file.length() > 0) {
        task.status = DownloadStatus.completed;
        task.progress = 1.0;
      } else {
        task.status = DownloadStatus.failed;
        task.errorMessage = 'File not saved properly';
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        task.status = DownloadStatus.paused;
      } else {
        task.status = DownloadStatus.failed;
        task.errorMessage = e.message ?? 'Download failed';
      }
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.errorMessage = e.toString();
    }

    _notifyListener(task.id, task);
    await _saveTasksToStorage();
  }

  // ─── PAUSE / RESUME / CANCEL ───────────────────────────────────────────────
  Future<void> pauseDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    task.cancelToken?.cancel('Paused by user');
    task.status = DownloadStatus.paused;
    _notifyListener(taskId, task);
    await _saveTasksToStorage();
  }

  Future<void> resumeDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    if (task.status != DownloadStatus.paused &&
        task.status != DownloadStatus.failed) return;

    task.cancelToken = CancelToken();
    task.status = DownloadStatus.downloading;
    _notifyListener(taskId, task);
    await _saveTasksToStorage();
    _downloadFile(task);
  }

  Future<void> cancelDownload(String taskId) async {
    final task = _tasks[taskId];
    if (task == null) return;
    task.cancelToken?.cancel('Cancelled by user');

    // Delete partial file
    try {
      final file = File(task.savePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    _tasks.remove(taskId);
    _notifyListener(taskId, task);
    await _saveTasksToStorage();
  }

  Future<void> deleteDownload(String taskId) async {
    await cancelDownload(taskId);
  }

  // ─── GETTERS ───────────────────────────────────────────────────────────────
  List<DownloadTask> get allTasks => _tasks.values.toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

  List<DownloadTask> get completedDownloads => _tasks.values
      .where((t) => t.status == DownloadStatus.completed)
      .toList();

  List<DownloadTask> get activeDownloads => _tasks.values
      .where((t) => t.status == DownloadStatus.downloading ||
          t.status == DownloadStatus.queued)
      .toList();

  DownloadTask? getTask(String movieId, String quality) =>
      _tasks['${movieId}_$quality'];

  bool isDownloaded(String movieId) => _tasks.values.any(
      (t) => t.movieId == movieId && t.status == DownloadStatus.completed);

  bool isDownloading(String movieId) => _tasks.values.any((t) =>
      t.movieId == movieId && t.status == DownloadStatus.downloading);

  List<DownloadTask> getTasksForMovie(String movieId) => _tasks.values
      .where((t) => t.movieId == movieId)
      .toList();

  // Total storage used by completed downloads
  Future<double> get totalStorageUsedMB async {
    double total = 0;
    for (final task in completedDownloads) {
      try {
        final file = File(task.savePath);
        if (await file.exists()) {
          total += await file.length() / 1024 / 1024;
        }
      } catch (_) {}
    }
    return total;
  }

  // ─── LISTENERS ─────────────────────────────────────────────────────────────
  void addListener(String taskId, Function(DownloadTask) callback) {
    _listeners[taskId] = callback;
  }

  void removeListener(String taskId) {
    _listeners.remove(taskId);
  }

  void _notifyListener(String taskId, DownloadTask task) {
    _listeners[taskId]?.call(task);
    _listeners['*']?.call(task); // Global listener
  }

  // ─── PERSISTENCE ───────────────────────────────────────────────────────────
  Future<void> _saveTasksToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = _tasks.map(
          (k, v) => MapEntry(k, jsonEncode(v.toJson())));
      await prefs.setString(
          _storageKey, jsonEncode(tasksJson));
    } catch (_) {}
  }

  Future<void> _loadTasksFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final Map<String, dynamic> tasksJson = jsonDecode(raw);
      for (final entry in tasksJson.entries) {
        try {
          final task = DownloadTask.fromJson(
              jsonDecode(entry.value));
          // Verify file still exists for completed tasks
          if (task.status == DownloadStatus.completed) {
            final file = File(task.savePath);
            if (!await file.exists()) {
              task.status = DownloadStatus.failed;
              task.errorMessage = 'File was deleted';
            }
          }
          _tasks[entry.key] = task;
        } catch (_) {}
      }
    } catch (_) {}
  }
}
