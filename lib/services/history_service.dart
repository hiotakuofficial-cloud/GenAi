import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HistoryService {
  static const String _historyFileName = 'chat_sessions.json';
  
  static Future<String> get _historyPath async {
    final directory = await getExternalStorageDirectory();
    final hisuDir = Directory('${directory!.path}/Android/data/com.amit.genai/files');
    if (!await hisuDir.exists()) {
      await hisuDir.create(recursive: true);
    }
    return '${hisuDir.path}/$_historyFileName';
  }

  static Future<List<ChatSession>> loadAllSessions() async {
    try {
      final path = await _historyPath;
      final file = File(path);
      
      if (!await file.exists()) {
        return [];
      }
      
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((json) => ChatSession.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveSession(ChatSession session) async {
    try {
      final sessions = await loadAllSessions();
      
      // Find existing session or add new one
      final existingIndex = sessions.indexWhere((s) => s.id == session.id);
      if (existingIndex != -1) {
        sessions[existingIndex] = session;
      } else {
        sessions.insert(0, session); // Add new session at top
      }
      
      // Keep only last 50 sessions
      if (sessions.length > 50) {
        sessions.removeRange(50, sessions.length);
      }
      
      final path = await _historyPath;
      final file = File(path);
      await file.writeAsString(jsonEncode(sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> deleteSession(String sessionId) async {
    try {
      final sessions = await loadAllSessions();
      sessions.removeWhere((s) => s.id == sessionId);
      
      final path = await _historyPath;
      final file = File(path);
      await file.writeAsString(jsonEncode(sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> clearAllHistory() async {
    try {
      final path = await _historyPath;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SessionMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List)
          .map((m) => SessionMessage.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<SessionMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

class SessionMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? type; // 'text', 'image', 'video'
  final String? prompt; // For media generation

  SessionMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.type = 'text',
    this.prompt,
  });

  factory SessionMessage.fromJson(Map<String, dynamic> json) {
    return SessionMessage(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      prompt: json['prompt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'prompt': prompt,
    };
  }
}
