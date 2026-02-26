import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as dev;

class GeminiService {
  static const String _apiKey = "AIzaSyAuXPA6pCsyfkL1dlEjWtrIlmNYuGfhhw4";

  static Future<String> sendMessage(String prompt) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are a professional AI finance assistant. Answer clearly, avoid legal advice, and use simple language.\n\nUser: $prompt",
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      dev.log(
        "Gemini error: ${response.body}",
        name: 'api.gemini',
        level: 1000, // 1000 is the standard for 'shout' or severe errors
        error: 'Status Code: ${response.statusCode}',
      );
      return "Gemini error: ${response.statusCode}";
    }
  }
}
