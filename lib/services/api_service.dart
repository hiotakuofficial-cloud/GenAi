import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String key1 = String.fromEnvironment('KEY_1');
  static const String key2 = String.fromEnvironment('KEY_2');
  static const String token = String.fromEnvironment('TOKEN');

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'key1': key1,
    'key2': key2,
    'token': token,
  };

  static Future<void> _saveChatHistory(List<Map<String, String>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(messages);
    await prefs.setString('chat_history', jsonString);
  }

  static Future<List<Map<String, String>>> _getChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('chat_history');
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>().map((e) => Map<String, String>.from(e)).toList();
    }
    return [];
  }

  static Future<String> sendMessage(String message, {String? sessionId}) async {
    try {
      // Get last 20 messages for context
      final history = await _getChatHistory();
      final last20 = history.length > 20 ? history.sublist(history.length - 20) : history;
      
      // Add current message to history
      last20.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse('$baseUrl/ai/ai.php?action=chat'),
        headers: _headers,
        body: jsonEncode({
          'message': message,
          'history': last20,
          'personality': '',
          'language': '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          String cleanResponse = data['response'] ?? 'No response';
          // Remove markdown formatting
          cleanResponse = cleanResponse.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
          cleanResponse = cleanResponse.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
          cleanResponse = cleanResponse.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
          cleanResponse = cleanResponse.replaceAll(RegExp(r'#{1,6}\s*'), '');
          
          // Save bot response to history
          last20.add({'role': 'assistant', 'content': cleanResponse});
          await _saveChatHistory(last20);
          
          return cleanResponse;
        }
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<Map<String, String>>> loadChatHistory() async {
    return await _getChatHistory();
  }

  static Future<String> generateImage(String prompt) async {
    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse('$baseUrl/ai/ai.php?action=image'),
        headers: _headers,
        body: jsonEncode({'prompt': prompt}),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['image_url'] ?? '';
        }
        throw Exception(data['error'] ?? 'Failed to generate image');
      }
      throw Exception('HTTP ${response.statusCode}: Failed to generate image');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<String> generateVideo(String prompt, {String type = 'basic'}) async {
    try {
      final client = http.Client();
      final response = await client.post(
        Uri.parse('$baseUrl/ai/ai.php?action=video'),
        headers: _headers,
        body: jsonEncode({
          'prompt': prompt,
          'type': type,
        }),
      ).timeout(const Duration(minutes: 50));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['video_url'] ?? '';
        }
        throw Exception(data['error'] ?? 'Failed to generate video');
      }
      throw Exception('HTTP ${response.statusCode}: Failed to generate video');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ai/ai.php?action=health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
