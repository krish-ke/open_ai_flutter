import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:pinch_zoom/pinch_zoom.dart';

class ChatImageScreen extends StatefulWidget {
  const ChatImageScreen({super.key});

  @override
  State<ChatImageScreen> createState() => _ChatImageScreenState();
}

class _ChatImageScreenState extends State<ChatImageScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String apiKey = 'ddc-a4f-e1fbe58d4cb74e0e8f7c7f70e2b2aecc';
  final List<Map<String, dynamic>> messages = [];

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

    // Determine if prompt is for image generation (e.g., start with "/image" command)
    final isImageRequest = prompt.trim().toLowerCase().startsWith('/image');

    setState(() {
      messages.add({'role': 'user', 'content': prompt, 'type': 'text'});
      messages.add({'role': 'generating', 'content': '', 'type': isImageRequest ? 'loading-image' : 'loading-text'});
      _loading = true;
      _stopRequested = false;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      if (isImageRequest) {
        // Image generation request
        final imagePrompt = prompt.trim().substring(6).trim(); // remove "/image"
        final response = await http.post(
          Uri.parse('https://api.a4f.co/v1/images/generations'),
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode({'model': 'provider-3/dall-e-3', 'prompt': imagePrompt, 'n': 1, 'size': '1024x1024'}),
        );

        if (_stopRequested) return;

        setState(() {
          messages.removeWhere((m) => m['role'] == 'generating');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final images = (data['data'] as List<dynamic>? ?? []).map((item) => item['url'] as String? ?? '').where((url) => url.isNotEmpty).toList();

            if (images.isNotEmpty) {
              for (var url in images) {
                messages.add({'role': 'assistant', 'content': url, 'type': 'image'});
              }
            } else {
              messages.add({'role': 'assistant', 'content': 'No image returned', 'type': 'text'});
            }
          } else {
            messages.add({'role': 'assistant', 'content': 'Error: ${response.statusCode}', 'type': 'text'});
          }

          _loading = false;
        });
      } else {
        // Chat text request
        final response = await http.post(
          Uri.parse('https://api.a4f.co/v1/chat/completions'),
          headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': 'provider-3/gpt-4',
            'messages': messages.where((m) => m['role'] != 'generating' && m['role'] != 'loading').map((m) => {'role': m['role'], 'content': m['content']}).toList(),
          }),
        );

        if (_stopRequested) return;

        setState(() {
          messages.removeWhere((m) => m['role'] == 'generating');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final reply = data['choices'][0]['message']['content'];
            messages.add({'role': 'assistant', 'content': reply, 'type': 'text'});
          } else {
            messages.add({'role': 'assistant', 'content': 'Error: ${response.statusCode}', 'type': 'text'});
          }

          _loading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        messages.removeWhere((m) => m['role'] == 'generating');
        messages.add({'role': 'assistant', 'content': 'Error: $e', 'type': 'text'});
      });
    }
  }

  void stopResponse() {
    setState(() {
      _stopRequested = true;
      _loading = false;

      messages.removeWhere((m) => m['role'] == 'generating');

      if (messages.isNotEmpty && messages.last['role'] == 'user') {
        messages.removeLast();
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final role = message['role'] as String;
    final content = message['content'] as String? ?? '';
    final type = message['type'] as String? ?? 'text';

    if (role == 'generating') {
      if (type == 'loading-text') {
        // Typing dots animation or simple "typing..."
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            child: const Text("Typing...", style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        );
      } else if (type == 'loading-image') {
        // Image loading spinner or placeholder
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text("Generating image...", style: TextStyle(fontStyle: FontStyle.italic))],
            ),
          ),
        );
      }
    }

    final isUser = role == 'user';

    if (type == 'image') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PinchZoom(
                  maxScale: 3.0,
                  child: Image.network(
                    content,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(width: 250, height: 250, child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Image URL', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image URL copied to clipboard')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Default: Text message with markdown for assistant, plain for user
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
                ? Text(content, style: const TextStyle(color: Colors.white))
                : MarkdownBody(data: content, styleSheet: MarkdownStyleSheet(codeblockDecoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)), code: const TextStyle(fontFamily: 'SourceCodePro', color: Colors.white))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat & Image Generation'), centerTitle: true, backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(child: ListView.builder(controller: _scrollController, padding: const EdgeInsets.symmetric(vertical: 12), itemCount: messages.length, itemBuilder: (context, index) => _buildMessage(messages[index]))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 5,
                      enabled: !_loading,
                      decoration: InputDecoration(hintText: 'Type message or /image prompt', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                      onSubmitted: (value) {
                        sendMessage(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  _loading
                      ? ElevatedButton.icon(onPressed: stopResponse, icon: const Icon(Icons.stop), label: const Text("Stop"), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white))
                      : CircleAvatar(backgroundColor: Colors.deepPurple, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () => sendMessage(_controller.text))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
