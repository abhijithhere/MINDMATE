// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class ApiService {

  // ── 🔐 Login ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _log('login error: $e');
      return {'error': e.toString()};
    }
  }

  // ── 📝 Signup with voice ──────────────────────────────────────────────────
  Future<bool> signup(
      String name, String email, String password, String voiceFilePath) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(ApiConstants.signup));
      req.fields['username'] = name;
      req.fields['user_id']  = email;
      req.fields['password'] = password;
      req.files.add(await http.MultipartFile.fromPath('voice_file', voiceFilePath));
      final s = await req.send().timeout(const Duration(seconds: 30));
      return s.statusCode == 200 || s.statusCode == 201;
    } catch (e) {
      _log('signup error: $e');
      return false;
    }
  }

  // ── 🎙️ Voice chunk upload ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadAudio(String userId, String filePath) async {
    if (userId.isEmpty) {
      _log('uploadAudio: empty userId');
      return _audioFallback();
    }
    try {
      final req = http.MultipartRequest('POST', Uri.parse(ApiConstants.uploadAudio));
      req.fields['user_id'] = userId;
      req.files.add(await http.MultipartFile.fromPath('file', filePath));
      final s   = await req.send().timeout(const Duration(seconds: 90));
      final res = await http.Response.fromStream(s);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      _log('uploadAudio ${res.statusCode}: ${res.body}');
      return _audioFallback();
    } catch (e) {
      _log('uploadAudio exception: $e');
      return _audioFallback();
    }
  }

  // ── 💬 Text chat ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendChatMessage(String userId, String text) async {
    if (userId.isEmpty) {
      return {'ai_response': 'User ID missing.', 'status': 'error'};
    }
    try {
      final req = http.MultipartRequest('POST', Uri.parse(ApiConstants.chatSend));
      req.fields['user_id'] = userId;
      req.fields['text']    = text;
      final s   = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(s);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      _log('sendChatMessage ${res.statusCode}: ${res.body}');
      return {'ai_response': '', 'status': 'error'};
    } catch (e) {
      _log('sendChatMessage exception: $e');
      return {'ai_response': '', 'status': 'error'};
    }
  }

  // ── 💬 Chat history ───────────────────────────────────────────────────────
  Future<List<dynamic>> getChatHistory(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/chat/history?user_id=$userId&limit=100'),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['history'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      _log('getChatHistory error: $e');
      return [];
    }
  }

  // ── 📊 Dashboard ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardData(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.dashboard}?user_id=$userId'),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      _log('getDashboardData error: $e');
      return {'error': 'Connection failed: $e'};
    }
  }

  // ── 📂 Memories ───────────────────────────────────────────────────────────
  Future<List<dynamic>> getMemories(String userId, {String? memoryType}) async {
    try {
      String url = '${ApiConstants.memories}?user_id=$userId';
      if (memoryType != null && memoryType != 'All') url += '&memory_type=$memoryType';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final d   = jsonDecode(res.body);
      if (d is Map && d.containsKey('timeline')) return d['timeline'] as List;
      return d is List ? d : [];
    } catch (e) {
      _log('getMemories error: $e');
      return [];
    }
  }

  // ── 🔮 Timetable ──────────────────────────────────────────────────────────
  Future<List<dynamic>> getTimetablePrediction(String userId, String targetDate) async {
    try {
      final res = await http.get(Uri.parse(
        '${ApiConstants.baseUrl}/predict-timetable?user_id=$userId&target_date=$targetDate',
      )).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return jsonDecode(res.body)['timetable'] as List;
      return [];
    } catch (e) {
      _log('getTimetablePrediction error: $e');
      return [];
    }
  }

  // ── 🗂️ ORGANIZED TASKS (High/Low Priority - FOOLPROOF METHOD) ────────────
  Future<List<dynamic>> getTasksByPage(String userId, String pageType) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/reminders/organized?user_id=$userId');
      debugPrint("🚀 CALLING API: $uri");
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint("📥 API RESPONSE (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Return Low Priority for Todo page, High Priority for Reminders page
        if (pageType == 'todo') {
          return List<dynamic>.from(data['todos'] ?? []);
        } else {
          return List<dynamic>.from(data['reminders'] ?? []);
          print("🟢 todos raw: ${data['todos']}");
          print("🟢 todos length: ${(data['todos'] ?? []).length}");
        }
      }
    } catch (e) {
      debugPrint("❌ CRITICAL API ERROR: $e");
    }
    return [];
  }

  // ── 📅 Filtered reminders (Backup method) ─────────────────────────────────
  Future<List<dynamic>> getFilteredReminders(String userId, List<String> priorities) async {
    try {
      final q   = priorities.map((p) => 'priorities=$p').join('&');
      final uri = Uri.parse('${ApiConstants.baseUrl}/reminders/filter?user_id=$userId&$q');
      debugPrint("🚀 CALLING API: $uri");

      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final decodedData = jsonDecode(res.body);
        return List<dynamic>.from(decodedData);
      }
      return [];
    } catch (e) {
      _log('getFilteredReminders error: $e');
      return [];
    }
  }
// ── ➕ Create manual reminder ─────────────────────────────────────────────
  Future<bool> createReminder(String userId, String message, String triggerTime, String priorityLevel) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/reminders/create');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "message": message,
          "trigger_time": triggerTime,
          "priority_level": priorityLevel
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      _log('createReminder error: $e');
      return false;
    }
  }
  // ── Gmail ─────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getGmailData(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/dashboard/gmail?user_id=$userId'),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['emails'] as List? ?? [];
      }
      return [];
    } catch (e) {
      _log('getGmailData error: $e');
      return [];
    }
  }

  Map<String, dynamic> _audioFallback() => {
    'transcript': '', 'ai_response': '',
    'auth_verified': false, 'flag': 0, 'action': 'error',
    'table': '', 'summary': '',
  };

  void _log(String msg) {
    assert(() { debugPrint('[ApiService] $msg'); return true; }());
  }
}