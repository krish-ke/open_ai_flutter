import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:open_ai/utils/app_colors.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String apiKey = 'ddc-a4f-e1fbe58d4cb74e0e8f7c7f70e2b2aecc';
  final List<Map<String, String>> messages = [];

  bool _loading = false;
  bool _stopRequested = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty || _loading) return;

    setState(() {
      messages.add({'role': 'user', 'content': prompt});
      messages.add({'role': 'typing', 'content': ''});
      _loading = true;
      _stopRequested = false;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.a4f.co/v1/chat/completions'),
        headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
        body: jsonEncode({'model': 'provider-3/gpt-4', 'messages': messages.where((m) => m['role'] != 'typing').toList()}),
      );

      if (_stopRequested) return;

      setState(() {
        messages.removeWhere((m) => m['role'] == 'typing');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final reply = data['choices'][0]['message']['content'];
          messages.add({'role': 'assistant', 'content': reply});
        } else {
          messages.add({'role': 'assistant', 'content': 'Error: ${response.statusCode}'});
        }

        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        messages.removeWhere((m) => m['role'] == 'typing');
        messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    }
  }

  void stopResponse() {
    setState(() {
      _stopRequested = true;
      _loading = false;

      // Remove "typing..." message if it exists
      messages.removeWhere((m) => m['role'] == 'typing');

      // Remove last assistant message if it exists
      if (messages.isNotEmpty && messages.last['role'] == 'user') {
        messages.removeLast();
      }
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    final role = message['role'];
    final content = message['content'] ?? '';

    if (role == 'typing') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          child: const Text("Typing...", style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }

    final isUser = role == 'user';

    // Extract code blocks from content
    String extractCodeBlocks(String markdown) {
      final regExp = RegExp(r'```([\s\S]*?)```', multiLine: true);
      final matches = regExp.allMatches(markdown);
      if (matches.isEmpty) return '';
      return matches.map((m) => m.group(1)?.trim() ?? '').join('\n\n');
    }

    final codeOnly = extractCodeBlocks(content);
    final hasCode = codeOnly.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUser ? 16 : 0), bottomRight: Radius.circular(isUser ? 0 : 16)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child:
            isUser
                ? Text(content, style: const TextStyle(color: Colors.white, fontStyle: FontStyle.normal))
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: MarkdownBody(
                        data: content,
                        styleSheet: MarkdownStyleSheet(
                          codeblockDecoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                          code: const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.greenAccent, backgroundColor: Colors.black87),
                          p: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                    if (hasCode) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: codeOnly));
                          // Optionally show feedback like SnackBar here
                        },
                        child: const Icon(Icons.copy, size: 20, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A4F AI Assistant'), backgroundColor: Colors.deepPurple, foregroundColor: AppColors.background),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.all(12), itemCount: messages.length, itemBuilder: (context, index) => _buildMessage(messages[index]))),
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)),
                      child: TextField(
                        controller: _controller,
                        enabled: !_loading,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(_controller.text),
                        decoration: const InputDecoration(hintText: 'Ask me anything...', border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _loading
                      ? ElevatedButton.icon(onPressed: stopResponse, icon: const Icon(Icons.stop), label: const Text("Stop"), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white))
                      : CircleAvatar(backgroundColor: Colors.deepPurple, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => sendMessage(_controller.text))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
