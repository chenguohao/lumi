import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

// 缓存完成回调类型
typedef CacheCompleteCallback = void Function(String url, String? filePath);

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  Directory? _cacheDir;
  final Set<String> _downloadingUrls = {};
  final List<String> _downloadQueue = []; // 下载队列
  bool _isProcessingQueue = false; // 是否正在处理队列
  final Map<String, List<CacheCompleteCallback>> _cacheCallbacks = {}; // 缓存完成回调
  final Map<String, bool> _hasNotifiedPartialCache = {}; // 是否已通知部分缓存

  Future<void> _ensureCacheDir() async {
    if (_cacheDir != null) return;
    
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/video_cache');
    print('[VideoCache] Cache directory: ${_cacheDir!.path}');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
      print('[VideoCache] Created cache directory');
    } else {
      print('[VideoCache] Cache directory already exists');
    }
  }

  String _getCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 从 URL 中提取文件扩展名
  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        final ext = path.substring(lastDot + 1).toLowerCase();
        // 只保留常见的视频扩展名
        if (['mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm', 'flv', '3gp'].contains(ext)) {
          return '.$ext';
        }
      }
    } catch (e) {
      print('[VideoCache] Error extracting extension from URL: $e');
    }
    // 默认使用 .mp4
    return '.mp4';
  }

  Future<File?> _getCachedFile(String url) async {
    await _ensureCacheDir();
    final key = _getCacheKey(url);
    final extension = _getFileExtension(url);
    final file = File('${_cacheDir!.path}/$key$extension');
    final exists = await file.exists();
    print('[VideoCache] Checking cache for URL: ${url.substring(0, url.length > 50 ? 50 : url.length)}...');
    print('[VideoCache] Cache key: $key');
    print('[VideoCache] File extension: $extension');
    print('[VideoCache] Cache file path: ${file.path}');
    print('[VideoCache] Cache file exists: $exists');
    
    if (exists) {
      try {
        final fileSize = await file.length();
        print('[VideoCache] Cache file size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
        return file;
      } catch (e) {
        print('[VideoCache] Error reading cache file info: $e');
        return null;
      }
    }
    return null;
  }

  Future<String?> getCachedVideoPath(String url) async {
    print('[VideoCache] Getting cached video path for URL: ${url.substring(0, url.length > 50 ? 50 : url.length)}...');
    final file = await _getCachedFile(url);
    if (file != null) {
      print('[VideoCache] ✓ Found cached video at: ${file.path}');
      return file.path;
    }
    print('[VideoCache] ✗ No cached video found');
    return null;
  }

  Future<bool> isVideoCached(String url) async {
    final file = await _getCachedFile(url);
    return file != null;
  }

  // 处理下载队列
  Future<void> _processDownloadQueue() async {
    if (_isProcessingQueue) {
      print('[VideoCache] Queue is already being processed');
      return;
    }

    _isProcessingQueue = true;
    print('[VideoCache] ===== Starting queue processing =====');
    print('[VideoCache] Queue length: ${_downloadQueue.length}');

    while (_downloadQueue.isNotEmpty) {
      final url = _downloadQueue.removeAt(0);
      print('[VideoCache] Processing queue item: ${url.substring(0, url.length > 50 ? 50 : url.length)}...');
      print('[VideoCache] Remaining in queue: ${_downloadQueue.length}');

      // 检查是否已缓存
      final cachedPath = await getCachedVideoPath(url);
      if (cachedPath != null) {
        print('[VideoCache] Video already cached, skipping');
        continue;
      }

      // 执行下载
      await _downloadVideoDirect(url);
    }

    _isProcessingQueue = false;
    print('[VideoCache] ===== Queue processing completed =====');
  }

  // 直接下载视频（流式下载，支持边下边播）
  Future<String?> _downloadVideoDirect(String url) async {
    print('[VideoCache] ===== Starting streaming video download =====');
    print('[VideoCache] URL: $url');
    
    _downloadingUrls.add(url);
    _hasNotifiedPartialCache[url] = false; // 初始化部分缓存通知标志
    print('[VideoCache] Added URL to downloading set');
    
    try {
      await _ensureCacheDir();
      final key = _getCacheKey(url);
      final extension = _getFileExtension(url);
      final file = File('${_cacheDir!.path}/$key$extension');
      print('[VideoCache] Target cache file: ${file.path}');
      print('[VideoCache] File extension: $extension');

      print('[VideoCache] Sending HTTP GET request (streaming mode)...');
      final startTime = DateTime.now();
      int totalBytes = 0;
      int? contentLength;
      
      // 使用流式下载，支持边下边播
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Range': 'bytes=0-', // 支持Range请求，允许部分下载
      });
      
      final client = http.Client();
      final streamedResponse = await client.send(request);
      
      // 获取内容长度
      contentLength = streamedResponse.contentLength;
      if (contentLength != null) {
        print('[VideoCache] Content-Length: ${contentLength} bytes (${(contentLength / 1024 / 1024).toStringAsFixed(2)} MB)');
      } else {
        print('[VideoCache] Content-Length: unknown (streaming)');
      }
      print('[VideoCache] Status code: ${streamedResponse.statusCode}');
      print('[VideoCache] Content-Type: ${streamedResponse.headers['content-type'] ?? 'unknown'}');
      
      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 206) {
        // 打开文件用于写入
        final sink = file.openWrite();
        DateTime lastProgressTime = DateTime.now();
        
        try {
          // 流式写入，边下载边写入
          await for (final chunk in streamedResponse.stream) {
            sink.add(chunk);
            totalBytes += chunk.length;
            
            // 每500ms或每1MB打印一次进度
            final now = DateTime.now();
            if (now.difference(lastProgressTime).inMilliseconds >= 500 || 
                totalBytes % (1024 * 1024) < chunk.length) {
              final progress = contentLength != null 
                  ? (totalBytes / contentLength * 100).toStringAsFixed(1)
                  : '?';
              final speed = totalBytes / now.difference(startTime).inMilliseconds * 1000; // bytes per second
              print('[VideoCache] Download progress: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB / ${contentLength != null ? (contentLength / 1024 / 1024).toStringAsFixed(2) : "?"} MB ($progress%) | Speed: ${(speed / 1024 / 1024).toStringAsFixed(2)} MB/s');
              lastProgressTime = now;
              
              // 如果下载了足够的数据（比如1MB），可以触发部分缓存回调
              // 这样播放器可以开始使用部分缓存的文件
              if (totalBytes >= 1024 * 1024) { // 至少1MB
                final callbacks = _cacheCallbacks[url];
                final hasNotified = _hasNotifiedPartialCache[url] ?? false;
                if (callbacks != null && callbacks.isNotEmpty && !hasNotified) {
                  _hasNotifiedPartialCache[url] = true;
                  print('[VideoCache] Partial cache available (${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB), file can be used for playback');
                  // 注意：这里不触发完整缓存回调，只记录部分缓存可用
                  // iOS video_player 支持部分文件播放，所以可以尝试使用部分缓存的文件
                }
              }
            }
          }
          
          await sink.close();
        } catch (e) {
          await sink.close();
          rethrow;
        }
        
        final duration = DateTime.now().difference(startTime);
        final fileSize = await file.length();
        final avgSpeed = fileSize / duration.inMilliseconds * 1000; // bytes per second
        
        print('[VideoCache] ✓ Video downloaded and saved successfully');
        print('[VideoCache] Total time: ${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms');
        print('[VideoCache] Saved file size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
        print('[VideoCache] Average speed: ${(avgSpeed / 1024 / 1024).toStringAsFixed(2)} MB/s');
        print('[VideoCache] Cache file path: ${file.path}');
        
        if (contentLength != null && fileSize != contentLength) {
          print('[VideoCache] ⚠ WARNING: File size mismatch! Expected: ${contentLength}, Got: $fileSize');
        }
        
        // 触发缓存完成回调
        final callbacks = _cacheCallbacks[url];
        if (callbacks != null && callbacks.isNotEmpty) {
          print('[VideoCache] Notifying ${callbacks.length} callback(s) for cache completion');
          for (final callback in callbacks) {
            try {
              callback(url, file.path);
            } catch (e) {
              print('[VideoCache] Error in cache completion callback: $e');
            }
          }
        }
        
        client.close();
        return file.path;
      } else {
        print('[VideoCache] ✗ Download failed with status code: ${streamedResponse.statusCode}');
        client.close();
        return null;
      }
    } catch (e, stackTrace) {
      print('[VideoCache] ✗ Video download error: $e');
      print('[VideoCache] Stack trace: $stackTrace');
      return null;
    } finally {
      _downloadingUrls.remove(url);
      _hasNotifiedPartialCache.remove(url);
      print('[VideoCache] Removed URL from downloading set');
      print('[VideoCache] ===== Streaming download process completed =====');
    }
  }

  // 通过队列下载视频（公共接口）
  Future<String?> downloadVideo(String url) async {
    print('[VideoCache] Requesting download for URL: ${url.substring(0, url.length > 50 ? 50 : url.length)}...');
    
    // 检查是否已缓存
    final cachedPath = await getCachedVideoPath(url);
    if (cachedPath != null) {
      print('[VideoCache] Video already cached, returning cached path');
      return cachedPath;
    }

    // 检查是否正在下载
    if (_downloadingUrls.contains(url)) {
      print('[VideoCache] Video is already being downloaded, waiting...');
      // 等待下载完成
      int waitCount = 0;
      while (_downloadingUrls.contains(url) && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 200));
        waitCount++;
        final cached = await getCachedVideoPath(url);
        if (cached != null) {
          print('[VideoCache] Download completed while waiting, returning cached path');
          return cached;
        }
      }
      print('[VideoCache] Timeout waiting for download to complete');
      return null;
    }

    // 检查是否在队列中
    if (_downloadQueue.contains(url)) {
      print('[VideoCache] Video is already in download queue');
      // 等待队列处理完成
      int waitCount = 0;
      while ((_downloadQueue.contains(url) || _downloadingUrls.contains(url)) && waitCount < 100) {
        await Future.delayed(const Duration(milliseconds: 200));
        waitCount++;
        final cached = await getCachedVideoPath(url);
        if (cached != null) {
          print('[VideoCache] Download completed from queue, returning cached path');
          return cached;
        }
      }
      print('[VideoCache] Timeout waiting for queue to process');
      return null;
    }

    // 添加到队列
    _downloadQueue.add(url);
    print('[VideoCache] Added URL to download queue (position: ${_downloadQueue.length})');
    
    // 启动队列处理（如果还没在处理）
    _processDownloadQueue();
    
    // 等待下载完成
    int waitCount = 0;
    while ((_downloadQueue.contains(url) || _downloadingUrls.contains(url)) && waitCount < 100) {
      await Future.delayed(const Duration(milliseconds: 200));
      waitCount++;
      final cached = await getCachedVideoPath(url);
      if (cached != null) {
        print('[VideoCache] Download completed from queue, returning cached path');
        return cached;
      }
    }
    
    print('[VideoCache] Timeout waiting for queue download');
    return null;
  }

  // 注册缓存完成回调
  void onCacheComplete(String url, CacheCompleteCallback callback) {
    _cacheCallbacks.putIfAbsent(url, () => []).add(callback);
    print('[VideoCache] Registered cache completion callback for URL: ${url.substring(0, url.length > 50 ? 50 : url.length)}...');
  }

  // 移除缓存完成回调
  void removeCacheCallback(String url, CacheCompleteCallback callback) {
    _cacheCallbacks[url]?.remove(callback);
    if (_cacheCallbacks[url]?.isEmpty ?? false) {
      _cacheCallbacks.remove(url);
    }
  }

  Future<void> preloadVideos(List<String> urls) async {
    print('[VideoCache] ===== Starting preload for ${urls.length} videos =====');
    
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      print('[VideoCache] Preloading video ${i + 1}/${urls.length}');
      
      // 检查是否已缓存
      final isCached = await isVideoCached(url);
      if (isCached) {
        print('[VideoCache] Video ${i + 1} already cached, skipping download but continuing to next');
        continue; // 跳过下载，但继续处理下一个
      }
      
      // 如果正在下载或在队列中，跳过
      if (_downloadingUrls.contains(url) || _downloadQueue.contains(url)) {
        print('[VideoCache] Video ${i + 1} is already in queue or downloading, skipping');
        continue;
      }
      
      // 按顺序添加到队列（即使前面的已缓存，也要继续添加后续的）
      _downloadQueue.add(url);
      print('[VideoCache] Added video ${i + 1} to download queue (position: ${_downloadQueue.length})');
    }
    
    print('[VideoCache] ===== Preload queue setup completed (${_downloadQueue.length} items) =====');
    
    // 启动队列处理（如果还没在处理）
    _processDownloadQueue();
  }

  Future<void> clearCache() async {
    await _ensureCacheDir();
    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  Future<int> getCacheSize() async {
    await _ensureCacheDir();
    if (!await _cacheDir!.exists()) return 0;
    
    int totalSize = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  // 清除特定 URL 的缓存
  Future<void> clearCacheForUrl(String url) async {
    try {
      print('[VideoCache] Clearing cache for URL: ${url.substring(0, url.length > 50 ? 50 : url.length)}...');
      await _ensureCacheDir();
      final key = _getCacheKey(url);
      final extension = _getFileExtension(url);
      final file = File('${_cacheDir!.path}/$key$extension');
      print('[VideoCache] Cache file to delete: ${file.path}');
      
      if (await file.exists()) {
        final fileSize = await file.length();
        await file.delete();
        print('[VideoCache] ✓ Deleted cache file (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
      } else {
        print('[VideoCache] Cache file does not exist, nothing to delete');
        // 也尝试删除没有扩展名的旧文件（兼容旧缓存）
        final oldFile = File('${_cacheDir!.path}/$key');
        if (await oldFile.exists()) {
          await oldFile.delete();
          print('[VideoCache] ✓ Deleted old cache file without extension');
        }
      }
    } catch (e, stackTrace) {
      print('[VideoCache] ✗ Error clearing cache for URL: $e');
      print('[VideoCache] Stack trace: $stackTrace');
    }
  }
}

