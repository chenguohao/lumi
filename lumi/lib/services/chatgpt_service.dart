import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPTService {
  final String apiKey = "45ea520d-cb9b-4e1c-be6d-9725f8580d9e";
  static const String apiUrl = "https://ark.cn-beijing.volces.com/api/v3/chat/completions";

  ChatGPTService();

  Future<String> getAIResponse({
    required String userMessage,
    required String aiName,
    required String aiPersonality,
  }) async {
    try {
      // 组装 Prompt
      final prompt = """
        you are $aiName，and you are $aiPersonality。
        user：$userMessage
       
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
            {"role": "system", "content": "you are an AI agent, Please respond in an appropriate style "},
            {"role": "user", "content": prompt}
          ],
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData["choices"][0]["message"]["content"];
      } else {
        throw Exception("API request Fail: ${responseData['error']['message']}");
      }
    } catch (e) {
      print("ChatGPTService Error: $e");
      return "sorry I can't answer that";
    }
  }
}
