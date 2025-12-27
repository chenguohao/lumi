import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/video_provider.dart';
import '../services/video_api_service.dart';
import '../models/video_model.dart';
import '../config/app_config.dart';

class VideoDetailPage extends StatefulWidget {
  final int videoId;
  
  const VideoDetailPage({super.key, required this.videoId});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  VideoModel? _video;
  bool _isLoading = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final video = await VideoApiService().getVideoDetail(widget.videoId);
      setState(() {
        _video = video;
        _isLoading = false;
      });
      _initializeVideo();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载视频失败: $e')),
        );
      }
    }
  }

  void _initializeVideo() {
    if (_video == null) return;
    
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(_video!.videoUrl),
    );
    
    _videoController!.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 9 / 16,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(AppConfig.primaryColor),
          handleColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          bufferedColor: Colors.white.withOpacity(0.1),
        ),
      );
      setState(() {
        _isPlaying = true;
      });
    });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
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
          // 背景图片
          CachedNetworkImage(
            imageUrl: _video!.coverUrl ?? _video!.videoUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(AppConfig.backgroundDark),
            ),
          ),
          // 渐变遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(AppConfig.backgroundDark).withOpacity(0.9),
                    Colors.transparent,
                    const Color(0xFF150A15).withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
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
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cast, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showMoreOptions(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 视频播放器
          if (_chewieController != null)
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          // 底部信息和控制
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 4),
                            Text(
                              'Episode 24 • Playing now',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
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
                            ),
                            onPressed: () => _toggleLike(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
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
                  const SizedBox(height: 16),
                  // 播放控制
                  _buildPlayControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: [
        Text(
          '04:20',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: 0.45,
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
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.45 - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(AppConfig.primaryColor),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          '12:45',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white),
          iconSize: 28,
          onPressed: () {},
        ),
        const SizedBox(width: 16),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(AppConfig.primaryColor).withOpacity(0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: const Color(AppConfig.primaryColor),
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
                if (_isPlaying) {
                  _videoController?.play();
                } else {
                  _videoController?.pause();
                }
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white),
          iconSize: 28,
          onPressed: () {},
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
