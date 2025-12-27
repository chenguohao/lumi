import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../config/app_config.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pull_to_refresh_indicator.dart';
import '../services/video_cache_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  bool _isInitialized = false;
  final VideoCacheService _cacheService = VideoCacheService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    
    if (refresh) {
      setState(() => _isRefreshing = true);
    }
    
    try {
      await provider.loadVideos();
      
      if (refresh) {
        setState(() => _isRefreshing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('刷新成功'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else if (!_isInitialized) {
        setState(() => _isInitialized = true);
        // 初始加载后预加载前3个视频
        _preloadVideos(provider.videos, 0);
      }
    } catch (e) {
      if (refresh) {
        setState(() => _isRefreshing = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载视频失败: $e')),
        );
      }
    }
  }

  void _preloadVideos(List<VideoModel> videos, int currentIndex) {
    if (videos.isEmpty) return;

    final urlsToPreload = <String>[];
    
    // 预加载当前、下一个、下下个（共3个，滑动窗口模式）
    // 即使某些视频已有缓存，也要继续检查后续视频并添加到队列
    for (int i = 0; i <= 2; i++) {
      final index = currentIndex + i;
      if (index >= 0 && index < videos.length) {
        final video = videos[index];
        if (video.videoUrl.isNotEmpty) {
          urlsToPreload.add(video.videoUrl);
        }
      }
    }

    print('[HomePage] Preloading videos for index $currentIndex (sliding window: ${currentIndex}, ${currentIndex + 1}, ${currentIndex + 2})');
    print('[HomePage] URLs to preload: ${urlsToPreload.length} videos');
    // 异步预加载，不阻塞UI
    // preloadVideos 会检查缓存，已缓存的跳过，未缓存的添加到队列
    _cacheService.preloadVideos(urlsToPreload);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<VideoProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // 内容区域
              if (provider.isLoading && !_isInitialized)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(AppConfig.primaryColor),
                  ),
                )
              else if (provider.videos.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '暂无视频',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadVideos(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(AppConfig.primaryColor),
                        ),
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              else
                // 视频列表（带下拉刷新）
                PullToRefreshIndicator(
                  onRefresh: () => _loadVideos(refresh: true),
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      provider.setCurrentIndex(index);
                      // 预加载相邻视频（当前、前一个、后一个）
                      _preloadVideos(provider.videos, index);
                      // 加载更多视频
                      if (index >= provider.videos.length - 2) {
                        provider.loadMoreVideos().then((_) {
                          // 加载更多后也预加载
                          if (mounted) {
                            _preloadVideos(provider.videos, index);
                          }
                        });
                      }
                    },
                    itemCount: provider.videos.length,
                    itemBuilder: (context, index) {
                      final video = provider.videos[index];
                      return _VideoItem(
                        key: ValueKey(video.id), // 使用key确保视频播放器正确重建
                        video: video,
                        onLike: () => provider.toggleLike(video.id),
                        onFavorite: () => provider.toggleFavorite(video.id),
                        onTap: () => context.push('/video/${video.id}'),
                      );
                    },
                  ),
                ),
              // 顶部标签切换和刷新按钮 - 始终显示
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Stack(
                  children: [
                    // 标签选择器 - 居中
                    Center(
                      child: _FeedTypeSelector(
                        feedType: provider.feedType,
                        onChanged: (type) {
                          provider.setFeedType(type);
                          provider.loadVideos();
                        },
                      ),
                    ),
                    // 刷新按钮 - 左侧
                    if (provider.videos.isNotEmpty)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _loadVideos(refresh: true),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: _isRefreshing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(AppConfig.primaryColor),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VideoItem extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onLike;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _VideoItem({
    super.key,
    required this.video,
    required this.onLike,
    required this.onFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 视频播放器（自动播放）
          VideoPlayerWidget(
            videoUrl: video.videoUrl,
            coverUrl: video.coverUrl,
            autoPlay: true,
            looping: true,
          ),
          // 渐变遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(AppConfig.backgroundDark).withOpacity(0.4),
                    Colors.transparent,
                    const Color(AppConfig.backgroundDark).withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // 底部信息卡片
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: _VideoInfoCard(
              video: video,
              onLike: onLike,
              onFavorite: onFavorite,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoInfoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onLike;
  final VoidCallback onFavorite;

  const _VideoInfoCard({
    required this.video,
    required this.onLike,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(AppConfig.backgroundDark).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(AppConfig.primaryColor).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // 角色头像
              GestureDetector(
                onTap: () => context.push('/character/${video.characterId}'),
                child: Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(AppConfig.primaryColor),
                            Colors.white,
                            Color(AppConfig.primaryColor),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: ClipOval(
                        child: (video.characterAvatar != null && video.characterAvatar!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: video.characterAvatar!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(AppConfig.surfaceDark),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(AppConfig.primaryColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(AppConfig.surfaceDark),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white54,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(AppConfig.surfaceDark),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(AppConfig.primaryColor),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(AppConfig.backgroundDark),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 角色信息和描述
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            (video.characterName != null && video.characterName!.isNotEmpty)
                                ? video.characterName!
                                : 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Symbols.verified,
                          color: Color(AppConfig.primaryColor),
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      video.title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 点赞按钮
              GestureDetector(
                onTap: onLike,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: video.isLiked
                          ? [
                              const Color(AppConfig.primaryColor).withOpacity(0.3),
                              const Color(AppConfig.primaryColor).withOpacity(0.1),
                            ]
                          : [
                              const Color(AppConfig.primaryColor).withOpacity(0.2),
                              const Color(AppConfig.primaryColor).withOpacity(0.1),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color(AppConfig.primaryColor).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Symbols.favorite,
                        color: video.isLiked
                            ? const Color(AppConfig.primaryColor)
                            : Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(video.likeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 收藏按钮
              GestureDetector(
                onTap: onFavorite,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Symbols.bookmark,
                    color: video.isFavorited
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _FeedTypeSelector extends StatelessWidget {
  final String feedType;
  final ValueChanged<String> onChanged;

  const _FeedTypeSelector({
    required this.feedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeedTypeButton(
                label: 'Following',
                isSelected: feedType == 'following',
                onTap: () => onChanged('following'),
              ),
              _FeedTypeButton(
                label: 'For You',
                isSelected: feedType == 'forYou',
                onTap: () => onChanged('forYou'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedTypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          border: isSelected
              ? Border.all(
                  color: Colors.white.withOpacity(0.05),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
