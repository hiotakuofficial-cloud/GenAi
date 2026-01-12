import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

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

  static Future<String> sendMessage(String message) async {
    if (baseUrl.isEmpty || key1.isEmpty || key2.isEmpty || token.isEmpty) {
      Fluttertoast.showToast(msg: 'Environment variables not set!');
      throw Exception('Missing environment variables');
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/ai.php?action=chat'),
        headers: _headers,
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['response'] ?? 'No response';
        }
        Fluttertoast.showToast(msg: 'API Error: ${data['error'] ?? 'Unknown'}');
      } else {
        Fluttertoast.showToast(msg: 'HTTP Error: ${response.statusCode}');
      }
      throw Exception('Failed to send message');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Network Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<String> generateImage(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/ai.php?action=image'),
        headers: _headers,
        body: jsonEncode({'prompt': prompt}),
      );

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
      final response = await http.post(
        Uri.parse('$baseUrl/ai/ai.php?action=video'),
        headers: _headers,
        body: jsonEncode({
          'prompt': prompt,
          'type': type,
        }),
      );

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
