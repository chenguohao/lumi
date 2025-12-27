import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';
import '../services/video_cache_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? coverUrl;
  final bool autoPlay;
  final bool looping;
  final VoidCallback? onTap; // 点击回调
  final ValueChanged<VideoPlayerValue>? onPlayerValueChanged; // 播放状态变化回调
  final ValueChanged<VideoPlayerController>? onPlayerControllerReady; // 播放器控制器就绪回调

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.coverUrl,
    this.autoPlay = true,
    this.looping = true,
    this.onTap, // 可选的点击回调
    this.onPlayerValueChanged, // 可选的播放状态变化回调
    this.onPlayerControllerReady, // 可选的播放器控制器就绪回调
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isLoadingCache = false;
  final VideoCacheService _cacheService = VideoCacheService();
  CacheCompleteCallback? _cacheCallback; // 缓存完成回调

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    // 注册缓存完成回调
    _cacheCallback = (url, filePath) {
      if (mounted && url == widget.videoUrl && filePath != null) {
        print('[VideoPlayer] Cache completed for current video, switching to cache...');
        _switchToCachedVideo(filePath);
      }
    };
    _cacheService.onCacheComplete(widget.videoUrl, _cacheCallback!);
  }

  void _setupPlayerListener() {
    if (_controller != null && widget.onPlayerValueChanged != null) {
      _controller!.addListener(_onPlayerValueChanged);
    }
  }

  void _onPlayerValueChanged() {
    if (_controller != null && widget.onPlayerValueChanged != null) {
      widget.onPlayerValueChanged!(_controller!.value);
    }
  }

  void _removePlayerListener() {
    if (_controller != null) {
      _controller!.removeListener(_onPlayerValueChanged);
    }
  }

  @override
  void dispose() {
    // 移除回调
    if (_cacheCallback != null) {
      _cacheService.removeCacheCallback(widget.videoUrl, _cacheCallback!);
    }
    _removePlayerListener();
    _controller?.dispose();
    super.dispose();
  }

  // 检查是否是格式不支持错误
  bool _isFormatNotSupportedError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('format is not supported') ||
           errorString.contains('osstatus error -12847') ||
           errorString.contains('cannot open');
  }

  Future<void> _initializePlayer() async {
    print('[VideoPlayer] ===== Initializing video player =====');
    print('[VideoPlayer] Video URL: ${widget.videoUrl}');
    print('[VideoPlayer] Cover URL: ${widget.coverUrl ?? 'none'}');
    print('[VideoPlayer] Auto play: ${widget.autoPlay}');
    print('[VideoPlayer] Looping: ${widget.looping}');
    
    try {
      setState(() {
        _isLoadingCache = true;
        _hasError = false;
      });

      // 先检查缓存
      print('[VideoPlayer] Step 1: Checking cache...');
      String? videoPath;
      final cachedPath = await _cacheService.getCachedVideoPath(widget.videoUrl);
      if (cachedPath != null) {
        videoPath = cachedPath;
        print('[VideoPlayer] ✓ Found cached video at: $videoPath');
        
        // 验证缓存文件
        try {
          final file = File(videoPath);
          final exists = await file.exists();
          final fileSize = exists ? await file.length() : 0;
          print('[VideoPlayer] Cache file exists: $exists');
          print('[VideoPlayer] Cache file size: ${fileSize} bytes (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)');
          
          if (!exists || fileSize == 0) {
            print('[VideoPlayer] ⚠ Cache file is invalid (missing or empty), will try network');
            videoPath = null;
          }
        } catch (e) {
          print('[VideoPlayer] ✗ Error checking cache file: $e');
          videoPath = null;
        }
      } else {
        print('[VideoPlayer] ✗ No cached video found');
      }

      // 尝试初始化视频播放器
      bool initSuccess = false;
      bool formatNotSupported = false;
      
      if (videoPath != null) {
        // 尝试使用本地缓存文件
        print('[VideoPlayer] Step 2: Attempting to initialize from cache file...');
        print('[VideoPlayer] Cache file path: $videoPath');
        try {
          _controller = VideoPlayerController.file(File(videoPath));
          print('[VideoPlayer] VideoPlayerController created, initializing...');
          await _controller!.initialize();
          print('[VideoPlayer] ✓ Successfully initialized from cache');
          print('[VideoPlayer] Video duration: ${_controller!.value.duration}');
          print('[VideoPlayer] Video size: ${_controller!.value.size.width}x${_controller!.value.size.height}');
          initSuccess = true;
        } catch (e, stackTrace) {
          print('[VideoPlayer] ✗ Failed to initialize from cache: $e');
          print('[VideoPlayer] Error type: ${e.runtimeType}');
          print('[VideoPlayer] Stack trace: $stackTrace');
          print('[VideoPlayer] Failed file path: $videoPath');
          
          // 检查文件是否存在和可读
          try {
            final file = File(videoPath);
            final exists = await file.exists();
            final readable = exists ? await file.readAsBytes().then((_) => true).catchError((_) => false) : false;
            print('[VideoPlayer] File exists: $exists');
            print('[VideoPlayer] File readable: $readable');
            if (exists) {
              final fileSize = await file.length();
              print('[VideoPlayer] File size: ${fileSize} bytes');
            }
          } catch (fileCheckError) {
            print('[VideoPlayer] Error checking file: $fileCheckError');
          }
          
          // 检查是否是格式不支持错误
          if (_isFormatNotSupportedError(e)) {
            formatNotSupported = true;
            print('[VideoPlayer] ⚠ Video format not supported by iOS. Removing corrupted cache file.');
            // 删除损坏的缓存文件
            try {
              await File(videoPath).delete();
              print('[VideoPlayer] Deleted corrupted cache file');
              await _cacheService.clearCacheForUrl(widget.videoUrl);
            } catch (deleteError) {
              print('[VideoPlayer] ✗ Failed to delete corrupted cache: $deleteError');
            }
          }
          
          _controller?.dispose();
          _controller = null;
        }
      }
      
      // 如果缓存失败且不是格式问题，尝试网络播放（支持边下边播）
      if (!initSuccess && !formatNotSupported && 
          (widget.videoUrl.startsWith('http') || widget.videoUrl.startsWith('https'))) {
        print('[VideoPlayer] Step 3: Attempting to initialize from network URL (streaming mode)...');
        print('[VideoPlayer] Network URL: ${widget.videoUrl}');
        print('[VideoPlayer] Note: iOS video_player supports streaming playback, video will play while downloading');
        try {
          _controller = VideoPlayerController.networkUrl(
            Uri.parse(widget.videoUrl),
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept': '*/*',
              'Accept-Language': 'en-US,en;q=0.9',
              'Range': 'bytes=0-', // 支持Range请求，允许流式播放
            },
          );
          print('[VideoPlayer] VideoPlayerController created for network URL, initializing...');
          await _controller!.initialize();
          print('[VideoPlayer] ✓ Successfully initialized from network (streaming)');
          print('[VideoPlayer] Video duration: ${_controller!.value.duration}');
          print('[VideoPlayer] Video size: ${_controller!.value.size.width}x${_controller!.value.size.height}');
          print('[VideoPlayer] Video will stream while downloading in background');
          initSuccess = true;
        } catch (e, stackTrace) {
          print('[VideoPlayer] ✗ Failed to initialize from network: $e');
          print('[VideoPlayer] Error type: ${e.runtimeType}');
          print('[VideoPlayer] Stack trace: $stackTrace');
          print('[VideoPlayer] Failed network URL: ${widget.videoUrl}');
          
          // 检查是否是格式不支持错误
          if (_isFormatNotSupportedError(e)) {
            formatNotSupported = true;
            print('[VideoPlayer] ⚠ Video format not supported by iOS from network URL.');
          }
          
          _controller?.dispose();
          _controller = null;
        }
      }
      
      // 如果格式不支持，直接标记为错误，不再尝试
      if (formatNotSupported) {
        print('[VideoPlayer] ⚠ Video format not supported, showing placeholder');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoadingCache = false;
          });
        }
        print('[VideoPlayer] ===== Initialization failed (format not supported) =====');
        return;
      }
      
      if (!initSuccess) {
        print('[VideoPlayer] ✗ All initialization attempts failed');
        throw Exception('Failed to initialize video player');
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoadingCache = false;
        });
        
        // 设置播放器监听器
        _setupPlayerListener();
        
        // 通知外部控制器已就绪
        if (widget.onPlayerControllerReady != null) {
          widget.onPlayerControllerReady!(_controller!);
        }
        
        if (widget.autoPlay) {
          print('[VideoPlayer] Starting auto-play...');
          _controller!.play();
        }
        
        if (widget.looping) {
          print('[VideoPlayer] Setting looping mode...');
          _controller!.setLooping(true);
        }
      }
      
      print('[VideoPlayer] ===== Initialization completed successfully =====');
    } catch (e, stackTrace) {
      print('[VideoPlayer] ✗ Video initialization error: $e');
      print('[VideoPlayer] Error type: ${e.runtimeType}');
      print('[VideoPlayer] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoadingCache = false;
        });
      }
      print('[VideoPlayer] ===== Initialization failed =====');
    }
  }

  // 切换到缓存视频
  Future<void> _switchToCachedVideo(String cachedPath) async {
    // 如果还没有初始化，直接切换到缓存并初始化
    if (!_isInitialized || _controller == null) {
      print('[VideoPlayer] Video not initialized yet, switching to cache and initializing...');
      try {
        // 如果控制器存在但未初始化，先释放
        if (_controller != null) {
          await _controller!.dispose();
        }
        
        // 创建新的控制器使用缓存文件
        _controller = VideoPlayerController.file(File(cachedPath));
        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoadingCache = false;
            _hasError = false;
          });
          
          // 设置播放器监听器
          _setupPlayerListener();
          
          // 通知外部控制器已就绪
          if (widget.onPlayerControllerReady != null) {
            widget.onPlayerControllerReady!(_controller!);
          }
          
          if (widget.autoPlay) {
            print('[VideoPlayer] Starting auto-play from cache...');
            _controller!.play();
          }
          
          if (widget.looping) {
            _controller!.setLooping(true);
          }
          
          print('[VideoPlayer] ✓ Successfully initialized from cache and started playback');
        }
        return;
      } catch (e, stackTrace) {
        print('[VideoPlayer] ✗ Failed to initialize from cache: $e');
        print('[VideoPlayer] Stack trace: $stackTrace');
        return;
      }
    }

    // 如果已经初始化，检查是否需要切换到缓存
    try {
      final currentValue = _controller!.value;
      if (currentValue.isInitialized) {
        // 如果正在缓冲或还没开始播放，切换到缓存
        if (currentValue.isBuffering || !currentValue.isPlaying) {
          print('[VideoPlayer] Video is buffering or not playing, switching to cache for better performance...');
        } else {
          // 即使正在播放，也切换到缓存（可以获得更好的性能，避免网络中断）
          print('[VideoPlayer] Video is playing, switching to cache for better performance...');
        }
      }
    } catch (e) {
      print('[VideoPlayer] Error checking controller state: $e');
    }

    try {
      print('[VideoPlayer] Switching to cached video: $cachedPath');
      
      // 保存当前播放位置
      final wasPlaying = _controller?.value.isPlaying ?? false;
      final position = _controller?.value.position ?? Duration.zero;
      
      // 移除旧控制器的监听器
      _removePlayerListener();
      
      // 释放旧的控制器
      final oldController = _controller;
      _controller = null;
      if (oldController != null) {
        await oldController.dispose();
      }
      
      // 创建新的控制器使用缓存文件
      _controller = VideoPlayerController.file(File(cachedPath));
      await _controller!.initialize();
      
      if (mounted) {
        // 如果之前正在播放，继续播放
        if (wasPlaying && position > Duration.zero) {
          await _controller!.seekTo(position);
        }
        
        setState(() {
          _isInitialized = true;
          _isLoadingCache = false;
          _hasError = false;
        });
        
        // 设置播放器监听器
        _setupPlayerListener();
        
        // 通知外部控制器已就绪
        if (widget.onPlayerControllerReady != null) {
          widget.onPlayerControllerReady!(_controller!);
        }
        
        if (widget.autoPlay || wasPlaying) {
          print('[VideoPlayer] Resuming playback from cache...');
          _controller!.play();
        }
        
        if (widget.looping) {
          _controller!.setLooping(true);
        }
        
        print('[VideoPlayer] ✓ Successfully switched to cached video');
      }
    } catch (e, stackTrace) {
      print('[VideoPlayer] ✗ Failed to switch to cached video: $e');
      print('[VideoPlayer] Stack trace: $stackTrace');
      // 如果切换失败，保持原状态
    }
  }

  void _handleTap() {
    if (_controller == null || !_isInitialized) return;
    
    if (widget.onTap != null) {
      // 先执行外部回调
      widget.onTap!();
    } else {
      // 如果没有外部回调，内部处理播放/暂停
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    }
  }

  // 外部调用的播放/暂停方法
  void togglePlayPause(bool shouldPlay) {
    if (_controller == null || !_isInitialized) return;
    
    if (shouldPlay) {
      _controller!.play();
    } else {
      _controller!.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // 如果视频加载失败，显示封面图
      return _buildCoverImage();
    }

    if (!_isInitialized || _controller == null) {
      // 加载中显示封面图
      return _buildCoverImage();
    }

    Widget videoWidget = SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );

    // 包装 GestureDetector 以支持点击暂停/播放
    return GestureDetector(
      onTap: _handleTap,
      child: videoWidget,
    );
  }

  Widget _buildCoverImage() {
    // 如果有封面图URL，尝试加载
    if (widget.coverUrl != null && widget.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    
    // 没有封面图或封面图为空，直接显示占位图
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/video_placeholder.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // 如果占位图也加载失败，显示纯色背景
        return Container(
          color: const Color(AppConfig.backgroundDark),
          child: const Center(
            child: Icon(
              Icons.video_library,
              color: Colors.white54,
              size: 48,
            ),
          ),
        );
      },
    );
  }
}
