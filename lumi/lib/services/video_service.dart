import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class VideoGenerationService {
  final String apiKey = "1b6612d8-fb95-4044-8560-95f6913da997";
  static const String baseUrl = "https://ark.ap-southeast.bytepluses.com/api/v3/contents/generations";

  VideoGenerationService();

  // 创建视频生成任务
  Future<Map<String, dynamic>> createVideoTask({
    required String description,
    String? imageUrl,
    int duration = 5,
    bool cameraFixed = false,
  }) async {
    try {
      final content = [
        {
          "type": "text",
          "text": "$description --duration $duration --camerafixed $cameraFixed"
        }
      ];

      if (imageUrl != null) {
        content.add({
          "type": "image_url",
          "image_url": {"url": imageUrl}
        });
      }

      final response = await http.post(
        Uri.parse("$baseUrl/tasks"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "seedance-1-5-pro-251215",
          "content": content,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception("视频生成任务创建失败: ${responseData['error']?['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print("VideoGenerationService 错误: $e");
      rethrow;
    }
  }

  // 查询任务状态
  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tasks/$taskId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception("查询任务状态失败: ${responseData['error']?['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print("VideoGenerationService 错误: $e");
      rethrow;
    }
  }
}

