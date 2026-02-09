import 'dart:convert';
import 'package:http/http.dart' as http;

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
      print("Gemini error ${response.statusCode}: ${response.body}");
      return "Gemini error: ${response.statusCode}";
    }
  }
}
