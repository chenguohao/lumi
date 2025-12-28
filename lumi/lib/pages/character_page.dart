import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../models/character_model.dart';
import '../models/video_model.dart';
import '../services/character_api_service.dart';
import '../services/video_api_service.dart';
import '../services/chat_api_service.dart';
import '../config/app_config.dart';
import 'chat_conversation_page.dart';
import 'video_create_page.dart';
import 'video_detail_page.dart';

class CharacterPage extends StatefulWidget {
  final int characterId;
  
  const CharacterPage({super.key, required this.characterId});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  CharacterModel? _character;
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  bool _isLoadingVideos = false;
  final CharacterApiService _characterApi = CharacterApiService();
  final VideoApiService _videoApi = VideoApiService();
  final ChatApiService _chatApi = ChatApiService();

  @override
  void initState() {
    super.initState();
    _loadCharacter();
    _loadVideos();
  }

  Future<void> _loadCharacter() async {
    try {
      final character = await _characterApi.getCharacterDetail(widget.characterId);
      setState(() {
        _character = character;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载角色信息失败: $e')),
        );
      }
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoadingVideos = true);
    try {
      final videos = await _videoApi.getVideoList(
        limit: 20,
        offset: 0,
        characterId: widget.characterId,
      );
      setState(() {
        _videos = videos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() => _isLoadingVideos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载视频失败: $e')),
        );
      }
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(AppConfig.backgroundDark),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(AppConfig.primaryColor),
          ),
        ),
      );
    }

    if (_character == null) {
      return Scaffold(
        backgroundColor: const Color(AppConfig.backgroundDark),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            '角色不存在',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundDark),
      body: CustomScrollView(
        slivers: [
          // 角色封面和信息（包含导航栏）
          SliverAppBar(
            expandedHeight: 360,
            pinned: false,
            floating: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
             
              IconButton(
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面图
                  _buildCharacterHeader(),
                  // 导航栏渐变（从黑色到透明）
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120, // 导航栏区域高度
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6), // 顶部黑色
                            Colors.black.withOpacity(0.3), // 中间
                            Colors.transparent, // 底部透明
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 统计数据
          SliverToBoxAdapter(
            child: _buildStatsSection(),
          ),
          // 操作按钮
          SliverToBoxAdapter(
            child: _buildActionButtons(),
          ),
          // 视频列表
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: _buildVideoList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 封面图（优先使用 cover_image，如果没有则使用 avatar）
        if (_character!.coverImage != null && _character!.coverImage!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: _character!.coverImage!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(AppConfig.surfaceDark),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(AppConfig.primaryColor),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              // 如果 cover_image 加载失败，尝试使用 avatar
              if (_character!.avatar.isNotEmpty) {
                return CachedNetworkImage(
                  imageUrl: _character!.avatar,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: const Color(AppConfig.surfaceDark),
                    child: const Icon(
                      Icons.image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                );
              }
              return Container(
                color: const Color(AppConfig.surfaceDark),
                child: const Icon(
                  Icons.image,
                  color: Colors.white54,
                  size: 48,
                ),
              );
            },
          )
        else if (_character!.avatar.isNotEmpty)
          CachedNetworkImage(
            imageUrl: _character!.avatar,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(AppConfig.surfaceDark),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(AppConfig.primaryColor),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(AppConfig.surfaceDark),
              child: const Icon(
                Icons.image,
                color: Colors.white54,
                size: 48,
              ),
            ),
          )
        else
          Container(
            color: const Color(AppConfig.surfaceDark),
          ),
        // 渐变遮罩（底部渐变）
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent, // 顶部透明
                  Colors.transparent, // 中间
                  const Color(AppConfig.backgroundDark).withOpacity(0.2),
                  const Color(AppConfig.backgroundDark), // 底部深色
                ],
                stops: const [0.0, 0.5, 0.7, 1.0],
              ),
            ),
          ),
        ),
        // 角色信息
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Active 状态指示器
                if (_character!.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(AppConfig.primaryColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: const Color(AppConfig.primaryColor).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(AppConfig.primaryColor).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 动画圆点（ping 效果）
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 外层动画圆环
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(seconds: 2),
                                builder: (context, value, child) {
                                  return Container(
                                    width: 10 + (value * 8),
                                    height: 10 + (value * 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(AppConfig.primaryColor)
                                          .withOpacity(0.75 * (1 - value)),
                                    ),
                                  );
                                },
                                onEnd: () {
                                  if (mounted && _character!.isOnline) {
                                    setState(() {});
                                  }
                                },
                              ),
                              // 内层实心圆点
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(AppConfig.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Active',
                          style: TextStyle(
                            color: const Color(AppConfig.primaryColor),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // 角色名称
                Text(
                  _character!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // 角色描述
                Text(
                  _character!.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              ),
            ),
          ),
        ],
   );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(AppConfig.backgroundDark).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatCount(_character!.fanCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'FANS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _formatCount(_character!.likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'LIKES',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Lv. ${_character!.bondLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BOND',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          // Chat Now 按钮
          Expanded(
            child: GestureDetector(
              onTap: () => _handleChatNow(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(AppConfig.primaryColor),
                      Color(AppConfig.primaryColor),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(AppConfig.primaryColor).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.chat_bubble,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Chat Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Create Video 按钮
          Expanded(
            child: GestureDetector(
              onTap: () => _handleCreateVideo(),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(AppConfig.surfaceDark),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(AppConfig.primaryColor).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.videocam,
                      color: const Color(AppConfig.primaryColor),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create Video',
                      style: TextStyle(
                        color: const Color(AppConfig.primaryColor),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildVideoList() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Latest Vlogs 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Symbols.movie,
                      color: const Color(AppConfig.primaryColor),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Latest Vlogs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // if (_videos.isNotEmpty)
                //   GestureDetector(
                //     onTap: () {
                //       // TODO: 跳转到查看所有视频页面
                //     },
                //     child: Text(
                //       'View All',
                //       style: TextStyle(
                //         color: const Color(AppConfig.primaryColor),
                //         fontSize: 12,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
          // 视频网格
          if (_isLoadingVideos)
            Container(
              padding: const EdgeInsets.all(40),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(AppConfig.primaryColor),
                ),
              ),
            )
          else if (_videos.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Empty',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ),
            )
          else
            Container(color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.only(left: 16,right: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(top: 6),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 9 / 16,
                  ),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return _VideoThumbnail(
                      video: video,
                      onTap: () => context.push('/video/${video.id}'),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleChatNow() async {
    try {
      // 创建或获取聊天会话
      final session = await _chatApi.createChatSession(widget.characterId);
      // 跳转到聊天会话页面
      if (mounted) {
        context.push('/chat/${session.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建聊天会话失败: $e')),
        );
      }
    }
  }

  void _handleCreateVideo() {
    // 跳转到创建视频页面，传递角色ID
    context.push('/video/create', extra: {'characterId': widget.characterId});
  }
}

class _VideoThumbnail extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const _VideoThumbnail({
    required this.video,
    required this.onTap,
  });

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(AppConfig.surfaceDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频封面
            if (video.coverUrl != null && video.coverUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: video.coverUrl!,
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
                    Icons.video_library,
                    color: Colors.white54,
                    size: 32,
                  ),
                ),
              )
            else
              Container(
                color: const Color(AppConfig.surfaceDark),
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white54,
                  size: 32,
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
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // 视频信息
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white60,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(video.viewCount),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

