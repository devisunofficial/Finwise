import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_message.dart';

class ChatStorage {
  static const _chatKey = 'gemini_chat_messages';
  static const _startTimeKey = 'gemini_chat_start_time';
  static const int _expiryMinutes = 60;

  // ---------------- SAVE ----------------

  static Future<void> saveChats(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();

    // Save start time only once
    if (!prefs.containsKey(_startTimeKey)) {
      prefs.setInt(
        _startTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    final encoded = messages
        .map((m) => jsonEncode(m.toJson()))
        .toList();

    await prefs.setStringList(_chatKey, encoded);
  }

  // ---------------- LOAD ----------------

  static Future<List<ChatMessage>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();

    if (await getRemainingMinutes() == 0) {
      await clearChats();
      return [];
    }

    final stored = prefs.getStringList(_chatKey);
    if (stored == null) return [];

    return stored
        .map((e) => ChatMessage.fromJson(jsonDecode(e)))
        .toList();
  }

  // ---------------- EXPIRY ----------------

  static Future<int> getRemainingMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt(_startTimeKey);

    if (startMillis == null) return _expiryMinutes;

    final startTime =
        DateTime.fromMillisecondsSinceEpoch(startMillis);
    final elapsed =
        DateTime.now().difference(startTime).inMinutes;

    final remaining = _expiryMinutes - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  // ---------------- CLEAR ----------------

  static Future<void> clearChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatKey);
    await prefs.remove(_startTimeKey);
  }
}
