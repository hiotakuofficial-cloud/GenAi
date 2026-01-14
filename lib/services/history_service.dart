import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum MessageType { text, image, video }

class ChatMessage {
  final String content;
  final bool isUser;
  final MessageType type;
  final String prompt;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.type,
    this.prompt = '',
  });
}

class HistoryService {
  static const String _historyKey = 'chat_history';
  
  static Future<void> saveSessionMessages(String sessionId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _getHistory();
    
    // Convert messages to JSON
    final messagesJson = messages.map((msg) => {
      'content': msg.content,
      'isUser': msg.isUser,
      'type': msg.type.toString(),
      'prompt': msg.prompt,
    }).toList();
    
    history[sessionId] = messagesJson;
    await prefs.setString(_historyKey, jsonEncode(history));
  }
  
  static Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final history = await _getHistory();
    final messagesJson = history[sessionId] as List<dynamic>? ?? [];
    
    return messagesJson.map((json) {
      final map = json as Map<String, dynamic>;
      return ChatMessage(
        content: map['content'] ?? '',
        isUser: map['isUser'] ?? false,
        type: _parseMessageType(map['type'] ?? 'MessageType.text'),
        prompt: map['prompt'] ?? '',
      );
    }).toList();
  }
  
  static Future<List<String>> getAllSessions() async {
    final history = await _getHistory();
    return history.keys.toList()..sort((a, b) => b.compareTo(a)); // Latest first
  }
  
  static Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _getHistory();
    history.remove(sessionId);
    await prefs.setString(_historyKey, jsonEncode(history));
  }
  
  static Future<Map<String, dynamic>> _getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString(_historyKey) ?? '{}';
    return jsonDecode(historyString) as Map<String, dynamic>;
  }
  
  static MessageType _parseMessageType(String typeString) {
    switch (typeString) {
      case 'MessageType.image':
        return MessageType.image;
      case 'MessageType.video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }
}
