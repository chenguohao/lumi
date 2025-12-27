import 'package:flutter/material.dart';

class VideoDetailPage extends StatefulWidget {
  final int videoId;
  
  const VideoDetailPage({super.key, required this.videoId});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Video Detail Page - ID: ${widget.videoId}'),
      ),
    );
  }
}

