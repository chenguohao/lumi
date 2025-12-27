import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/video_provider.dart';
import '../services/video_api_service.dart';
import '../models/video_model.dart';
import '../config/app_config.dart';
import '../widgets/video_player_widget.dart';

class VideoDetailPage extends StatefulWidget {
  final int videoId;
  
  const VideoDetailPage({super.key, required this.videoId});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  VideoModel? _video;
  bool _isLoading = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _progressTimer;
  VideoPlayerController? _playerController;
  bool _isPlaying = false;
  bool _showCenterIcon = false;
  bool _isPausedIcon = false; // true 显示暂停图标，false 显示播放图标
  Timer? _hideIconTimer;
  bool _isInitialPlay = true; // 标记是否是初始播放（自动播放）
  bool _wasManuallyPaused = false; // 标记是否是用户手动暂停的

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _hideIconTimer?.cancel();
    super.dispose();
  }

  void _onPlayStateChanged(bool isPlaying) {
    if (_isPlaying != isPlaying) {
      final wasPaused = !_isPlaying;
      _isPlaying = isPlaying;
      
      if (isPlaying) {
        // 从暂停切换到播放：只有在用户手动暂停后才显示暂停图标，0.2秒后隐藏
        if (wasPaused && _wasManuallyPaused) {
          setState(() {
            _showCenterIcon = true;
            _isPausedIcon = true;
          });
          _hideIconTimer?.cancel();
          _hideIconTimer = Timer(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() {
                _showCenterIcon = false;
              });
            }
          });
          _wasManuallyPaused = false; // 重置标志
        }
        // 初始自动播放时不显示图标
        if (_isInitialPlay) {
          _isInitialPlay = false;
        }
      } else {
        // 暂停状态：显示播放图标
        // 只有在非初始状态下才标记为手动暂停
        if (!_isInitialPlay) {
          _wasManuallyPaused = true;
        }
        _hideIconTimer?.cancel();
        setState(() {
          _showCenterIcon = true;
          _isPausedIcon = false;
        });
      }
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    // 每 16ms 更新一次进度（约60fps），让进度条更平滑
    _progressTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_playerController != null && _playerController!.value.isInitialized) {
        if (mounted) {
          final isPlaying = _playerController!.value.isPlaying;
          _onPlayStateChanged(isPlaying);
          
          setState(() {
            _position = _playerController!.value.position;
            _duration = _playerController!.value.duration;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadVideo() async {
    try {
      final video = await VideoApiService().getVideoDetail(widget.videoId);
      setState(() {
        _video = video;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载视频失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(AppConfig.primaryColor),
          ),
        ),
      );
    }

    if (_video == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            '视频不存在',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 视频播放器（全屏平铺）
          _VideoPlayer(
            videoUrl: _video!.videoUrl,
            coverUrl: _video!.coverUrl,
            autoPlay: true,
            looping: true, // 自动循环播放
            onPlayerControllerReady: (controller) {
              _playerController = controller;
              _startProgressTimer();
            },
          ),
          // 渐变遮罩（顶部和底部）- 使用 IgnorePointer 让点击事件穿透
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(AppConfig.backgroundDark).withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFF150A15).withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.2, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // 全屏点击区域（用于暂停/播放）- 放在按钮区域之前，这样按钮可以覆盖它
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // 点击视频区域暂停/播放
                if (_playerController != null && _playerController!.value.isInitialized) {
                  if (_playerController!.value.isPlaying) {
                    _playerController!.pause();
                  } else {
                    _playerController!.play();
                  }
                }
              },
              // 让点击事件穿透，但按钮区域会优先响应
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // 顶部导航栏
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cast, color: Colors.white, size: 20),
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _showMoreOptions(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 底部信息
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _video!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // 角色信息
                            if (_video!.characterName != null)
                              Row(
                                children: [
                                  if (_video!.characterAvatar != null)
                                    Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(AppConfig.primaryColor),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: _video!.characterAvatar!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: const Color(AppConfig.surfaceDark),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: const Color(AppConfig.surfaceDark),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white54,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    _video!.characterName!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _video!.isLiked ? Symbols.favorite : Symbols.favorite,
                              color: _video!.isLiked
                                  ? const Color(AppConfig.primaryColor)
                                  : Colors.white.withOpacity(0.9),
                              size: 28,
                            ),
                            onPressed: () => _toggleLike(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 进度条
                  _buildProgressBar(),
                ],
              ),
            ),
          ),
          // 中央播放/暂停图标
          if (_showCenterIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showCenterIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isPausedIcon ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    // 使用更精确的进度计算（毫秒级别）
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    
    // 计算剩余时间（倒计时）
    final remaining = _duration - _position;
    
    String formatDuration(Duration duration) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(AppConfig.primaryColor),
                      Color(AppConfig.primaryColor),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppConfig.primaryColor),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          '-${formatDuration(remaining)}', // 显示倒计时，前面加负号
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  void _toggleLike() {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    provider.toggleLike(_video!.id);
    setState(() {});
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(AppConfig.surfaceDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text('屏蔽内容', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现屏蔽功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.white),
              title: const Text('屏蔽用户', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现屏蔽用户功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('举报内容', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现举报功能
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义视频播放器组件，支持点击暂停/播放
class _VideoPlayer extends StatelessWidget {
  final String videoUrl;
  final String? coverUrl;
  final bool autoPlay;
  final bool looping;
  final ValueChanged<VideoPlayerController>? onPlayerControllerReady;

  const _VideoPlayer({
    super.key,
    required this.videoUrl,
    this.coverUrl,
    required this.autoPlay,
    required this.looping,
    this.onPlayerControllerReady,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(
      videoUrl: videoUrl,
      coverUrl: coverUrl,
      autoPlay: autoPlay,
      looping: looping,
      onPlayerControllerReady: onPlayerControllerReady,
      // onTap 为 null，VideoPlayerWidget 会内部处理点击暂停/播放
    );
  }
}
