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
    Fluttertoast.showToast(msg: 'BASE_URL: $baseUrl');
    Fluttertoast.showToast(msg: 'KEY_1: $key1');
    Fluttertoast.showToast(msg: 'TOKEN: ${token.substring(0, 10)}...');
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/ai.php?action=chat'),
        headers: _headers,
        body: jsonEncode({'message': message}),
      );

      Fluttertoast.showToast(msg: 'Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['response'] ?? 'No response';
        }
        Fluttertoast.showToast(msg: 'API Error: ${data['error'] ?? 'Unknown'}');
      }
      throw Exception('Failed to send message');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<String> generateImage(String prompt) async {
    try {
      Fluttertoast.showToast(msg: 'Generating image...');
      final response = await http.post(
        Uri.parse('$baseUrl/ai/ai.php?action=image'),
        headers: _headers,
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          Fluttertoast.showToast(msg: 'Image generated!');
          return data['image_url'] ?? '';
        }
        Fluttertoast.showToast(msg: 'Image error: ${data['error'] ?? 'Unknown'}');
      }
      throw Exception('Failed to generate image');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Image error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<String> generateVideo(String prompt, {String type = 'basic'}) async {
    try {
      Fluttertoast.showToast(msg: 'Generating video...');
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
          Fluttertoast.showToast(msg: 'Video generated!');
          return data['video_url'] ?? '';
        }
        Fluttertoast.showToast(msg: 'Video error: ${data['error'] ?? 'Unknown'}');
      }
      throw Exception('Failed to generate video');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Video error: $e');
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
