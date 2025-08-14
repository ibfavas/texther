import 'dart:convert';
import 'package:http/http.dart' as http;

class GptService {
  final String apiKey = "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"; // Keep this secure

  Future<String> generateMessage({
    required String mode,
    required String tone,
    required String userMessage,
  }) async {
    String prompt;

    if (mode == "Reply") {
      prompt =
      "Craft a response to the message: \"$userMessage\". Your reply should sound completely natural and human, reflecting a $tone tone.";
    } else {
      prompt =
      "Refine this message for grammar and clarity: \"$userMessage\". The goal is to make it sound perfectly natural and human, using a $tone tone.";
    }

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": "You are a helpful, friendly chat assistant."},
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.8
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["choices"][0]["message"]["content"].trim();
    } else {
      throw Exception("Failed to get GPT response: ${response.body}");
    }
  }
}
