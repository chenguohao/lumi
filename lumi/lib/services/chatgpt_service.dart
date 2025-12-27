import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPTService {
  final String apiKey = "45ea520d-cb9b-4e1c-be6d-9725f8580d9e";
  static const String apiUrl = "https://ark.cn-beijing.volces.com/api/v3/chat/completions";

  ChatGPTService();

  Future<String> getAIResponse({
    required String userMessage,
    required String aiName,
    required String aiOccupation,
    required int aiAge,
    required String aiLanguage,
  }) async {
    try {
      // 组装 Prompt
      final prompt = """
        你是 $aiName，$aiAge 岁的 $aiOccupation，你的母语是 $aiLanguage。
        用户：$userMessage
        请用 $aiLanguage 回复。
      """;

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "ep-20241217161036-48p9x",
          "temperature": 1.0,
          "top_p": 0.7,
          "n":1,
          "messages": [
            {"role": "system", "content": "你是一个智能助手，请用合适的风格回答问题。"},
            {"role": "user", "content": prompt}
          ],
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData["choices"][0]["message"]["content"];
      } else {
        throw Exception("API 请求失败: ${responseData['error']['message']}");
      }
    } catch (e) {
      print("ChatGPTService 错误: $e");
      return "对不起，我暂时无法回答你的问题。";
    }
  }
}
