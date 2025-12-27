import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/video_api_service.dart';

class VideoProvider with ChangeNotifier {
  final VideoApiService _videoService = VideoApiService();
  
  List<VideoModel> _videos = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  String _feedType = 'forYou'; // 'forYou' or 'following'

  List<VideoModel> get videos => _videos;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;
  String get feedType => _feedType;
  VideoModel? get currentVideo => _videos.isNotEmpty && _currentIndex < _videos.length 
      ? _videos[_currentIndex] 
      : null;

  Future<void> loadVideos({int? characterId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final videos = await _videoService.getVideoList(
        limit: 20,
        offset: 0,
        characterId: characterId,
      );
      _videos = videos;
      _currentIndex = 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMoreVideos({int? characterId}) async {
    try {
      final videos = await _videoService.getVideoList(
        limit: 20,
        offset: _videos.length,
        characterId: characterId,
      );
      _videos.addAll(videos);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _videos.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void setFeedType(String type) {
    _feedType = type;
    notifyListeners();
  }

  Future<void> toggleLike(int videoId) async {
    try {
      final video = _videos.firstWhere((v) => v.id == videoId);
      if (video.isLiked) {
        await _videoService.unlikeVideo(videoId);
        video.isLiked = false;
        video.likeCount = (video.likeCount - 1).clamp(0, double.infinity).toInt();
      } else {
        await _videoService.likeVideo(videoId);
        video.isLiked = true;
        video.likeCount++;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleFavorite(int videoId) async {
    try {
      final video = _videos.firstWhere((v) => v.id == videoId);
      if (video.isFavorited) {
        await _videoService.unfavoriteVideo(videoId);
        video.isFavorited = false;
      } else {
        await _videoService.favoriteVideo(videoId);
        video.isFavorited = true;
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

