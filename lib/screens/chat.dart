import 'package:flutter/material.dart';
import 'chat_message.dart';
import 'gemini_service.dart';
import 'chat_storage.dart';
import 'dart:async';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  int? _remainingMinutes;
  Timer? _expiryTimer;

  // ---------------- LIFECYCLE ----------------

  @override
  void initState() {
    super.initState();
    _restoreChat();
    _startExpiryTimer();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ---------------- CHAT LOGIC ----------------

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isTyping = true;
    });
    ChatStorage.saveChats(_messages);

    final response = await GeminiService.sendMessage(userMessage);

    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isTyping = false;
    });
    ChatStorage.saveChats(_messages);
  }

  // ---------------- STORAGE ----------------

  Future<void> _restoreChat() async {
    final savedMessages = await ChatStorage.loadChats();
    if (!mounted) return;

    setState(() {
      _messages.clear();
      _messages.addAll(savedMessages);
    });
  }

  // ---------------- EXPIRY TIMER ----------------

  void _startExpiryTimer() async {
    await _updateRemainingTime();

    _expiryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateRemainingTime(),
    );
  }

  Future<void> _updateRemainingTime() async {
    final minutes = await ChatStorage.getRemainingMinutes();
    if (!mounted) return;

    if (minutes == 0) {
      await ChatStorage.clearChats();
      setState(() {
        _messages.clear();
        _remainingMinutes = 0;
      });
    } else {
      setState(() {
        _remainingMinutes = minutes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("FinWise ChatBot"),
            if (_remainingMinutes != null)
              Text(
                "Chat expires in $_remainingMinutes min",
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Color(0xFF06163A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : Color(0xFF06163A),
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Gemini is typing...",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),

          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask FinWise AI ...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded),
            color: Color(0xFF06163A),
          ),
        ],
      ),
    );
  }
}
